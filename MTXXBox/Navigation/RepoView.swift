//
//  RepoView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/9.
//

import SwiftUI
import ObjectiveGit

struct RepoView: View {
    var repo: Repo
        
    @State private var gitRepo: GTRepository?
    
    @State private var workDirStatusDeltas: [GTStatusDelta] = []
    @State private var indexStatusDeltas: [GTStatusDelta] = []
    
    @State private var showAlert: Bool = false
    @State private var alertMsg: String = ""
        
    var body: some View {
        Group {
            if indexStatusDeltas.count == 0 && workDirStatusDeltas.count == 0 {
                Text("Working directory and index are clean")
            } else {
                NavigationView {
                    List {
                        Section {
                            ForEach(indexStatusDeltas, id: \.self) { delta in
                                item(of: delta, tipColor: .green, diffType: .headToIndex)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "tray")
                                Text("暂存区")
                            }
                        }
                        Section {
                            ForEach(workDirStatusDeltas, id: \.self) { delta in
                                item(of: delta, tipColor: .red, diffType: .indexToWorkDir)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "folder")
                                Text("工作区")
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .contextMenu {
            Button {
                gitStatus()
            } label: {
                Image(systemName: "arrow.clockwise")
                Text("刷新")
            }
        }
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text(alertMsg), message: nil, dismissButton: .default(Text("OK"), action: {
                showAlert = false
            }))
        })
        .onAppear {
            gitStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            gitStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshState"))) { _ in
            gitStatus()
        }
    }
    
    private func item(of statusDelta: GTStatusDelta, tipColor: Color, diffType: DiffType = .indexToWorkDir) -> some View {
        let path = statusDelta.oldFile?.path ?? statusDelta.newFile?.path ?? ""
        print("\(statusDelta.status):\(path)")
        
        let chNum = UInt8(git_diff_status_char(git_delta_t(rawValue: UInt32(statusDelta.status.rawValue))))
        let ch = Character(UnicodeScalar(chNum))
        return NavigationLink {
            if let gitRepo = self.gitRepo {
                RepoDiffView(gitRepo: gitRepo, filePath: path, statusDelta: statusDelta, diffType: diffType)
            }
        } label: {
            HStack {
                Text(String(ch))
                    .foregroundColor(tipColor)
                Text(path)
            }
        }
        .contextMenu {
            Button {
                stash(of: path, diffType: diffType)
            } label: {
                Text(diffType == .indexToWorkDir ? "暂存" : "取消暂存")
            }
        }
    }
    
    private func stash(of path: String, diffType: DiffType) {
        guard let workDir = MBoxCommand.sharedInstance.workDir else { return }
        // 修改工作目录
        MBoxCommand.sharedInstance.workDir = "\(workDir)/\(repo.name)"
        
        var result: (String?, String?) = (nil, nil)
        if diffType == .indexToWorkDir {
            result = MBoxCommand.sharedInstance.gitStash(for: path)
        } else {
            result = MBoxCommand.sharedInstance.gitUnstash(for: path)
        }
        
        // 恢复工作目录
        MBoxCommand.sharedInstance.workDir = workDir
        
        if result.1 == nil {
            gitStatus()
        } else {
            showAlert = true
            alertMsg = """
            \(diffType == .indexToWorkDir ? "暂存失败" : "取消暂存失败")
            
            \(result.1!)
            """
        }
    }
    
    private func gitStatus() {
        guard let workDir = MBoxCommand.sharedInstance.workDir else { return }
        indexStatusDeltas.removeAll()
        workDirStatusDeltas.removeAll()
        let url = URL(fileURLWithPath: "\(workDir)/\(repo.name)")
        do {
            let repo = try GTRepository(url: url)
            gitRepo = repo
            try repo.enumerateFileStatus(options: nil) { headToIndex, indexToWorkDir, stop in
                if let h2i = headToIndex, h2i.status != .ignored {
                    indexStatusDeltas.append(h2i)
                }
                if let i2w = indexToWorkDir, i2w.status != .ignored {
                    workDirStatusDeltas.append(i2w)
                }
            }
        } catch {
            print("初始化Repo失败:\(error)")
            showAlert = true
            alertMsg = """
            初始化Repo失败
            
            \(error)
            """
        }
    }
}

//struct RepoView_Previews: PreviewProvider {
//    static var previews: some View {
//        RepoView()
//    }
//}
