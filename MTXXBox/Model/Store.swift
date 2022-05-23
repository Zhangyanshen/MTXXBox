//
//  Store.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/25.
//

import Foundation

final class Store: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var selectedWorkspaceID: Workspace.ID?
    
    var selectedWorkspace: Workspace? {
        get {
            if selectedWorkspaceID == nil { return nil }
            return workspace(for: selectedWorkspaceID!)
        }
        set {
            guard let w = newValue else { return }
            let index = workspaces.firstIndex(of: w)
            if index != nil {
                workspaces[index!] = w
                selectedWorkspaceID = w.id
            }
        }
    }
    
    private var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    private let filename = "database.json"

    private var databaseFileUrl: URL {
        let dirUrl = applicationSupportDirectory.appendingPathComponent("mtxxbox")
        if !FileManager.default.fileExists(atPath: dirUrl.path) {
            try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
        }
        return dirUrl.appendingPathComponent(filename)
    }
    
    // MARK: - Init

    init() {
        if let data = FileManager.default.contents(atPath: databaseFileUrl.path) {
            workspaces = loadWorkspaces(from: data)
        } else {
            workspaces = []
        }
    }
    
    // MARK: - Private methods
    
    private func loadWorkspaces(from storeFileData: Data) -> [Workspace] {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Workspace].self, from: storeFileData)
        } catch {
            debugPrint(error)
            return []
        }
    }
    
    // MARK: - Public methods
    
    // 添加Workspace
    func append(_ workspace: Workspace) {
        workspaces.append(workspace)
        save()
    }
    
    // 删除Workspace
    func deleteWorkspace(_ workspace: Workspace) {
        workspaces.removeAll(where: { $0.id == workspace.id })
        if workspace.id == selectedWorkspaceID {
            selectedWorkspaceID = nil
        }
        save()
    }
    
    // 删除路径不存在的Workspace
    func deleteInvalidWorkspaces() {
        workspaces.removeAll { w in
            let exist = FileManager.default.fileExists(atPath: w.path)
            if !exist && w.id == selectedWorkspaceID {
                selectedWorkspaceID = nil
            }
            return !exist
        }
        save()
    }
    
    // 根据id获取Workspace
    func workspace(for id: Workspace.ID) -> Workspace? {
        workspaces.first { $0.id == id }
    }
    
    // Workspace是否存在
    func existWorkspace(for path: String) -> Bool {
        let existPaths = workspaces.filter { $0.path == path }
        return existPaths.count > 0
    }
    
    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(workspaces)
            if FileManager.default.fileExists(atPath: databaseFileUrl.path) {
                try FileManager.default.removeItem(at: databaseFileUrl)
            }
            try data.write(to: databaseFileUrl)
        } catch {
            debugPrint("保存失败")
        }
    }
}
