//
//  WorkspaceListView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/25.
//

import SwiftUI
import SwiftShell
import SwiftyJSON

enum AlertType {
    case normal, delete
}

struct WorkspaceListView: View {
    @EnvironmentObject var store: Store
    
    @State private var alertType: AlertType = .normal
    @State private var showAlert = false
    @State private var alertMsg = ""
    @State private var deleteWorkspace: Workspace?
    
    @State private var showLoading = false
    @State private var log = ""
    
    // MARK: - View
    
    var body: some View {
        VStack {
            if store.workspaces.count == 0 {
                emptyView
            } else {
                listView
            }
            Spacer()
            bottomButtonView
        }
        .frame(minWidth: 200)
        .alert(isPresented: $showAlert) {
            switch alertType {
            case .normal:
                return Alert(title: Text(alertMsg), dismissButton: .default(Text("OK")))
            case .delete:
                return Alert(title: Text("确认删除该workspace吗？"),
                      message: nil,
                      primaryButton: .destructive(Text("确认"),
                                                  action: {
                    guard let w = deleteWorkspace else { return }
                    store.deleteWorkspace(w)
                    deleteWorkspace = nil
                }),
                      secondaryButton: .cancel(Text("取消"), action: {
                    deleteWorkspace = nil
                }))
            }
        }
        .sheet(isPresented: $showLoading) {
            LoadingView(log: $log)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            store.deleteInvalidWorkspaces()
        }
    }
    
    // 无Workspace时的空view
    private var emptyView: some View {
        VStack {
            Spacer()
            Text("No Workspaces")
            Spacer()
        }
    }
    
    // workspace list
    private var listView: some View {
        List {
            Section {
                ForEach(store.workspaces) { workspace in
                    NavigationLink(tag: workspace.id,
                                   selection: $store.selectedWorkspaceID)
                    {
                        RepoListView()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workspace.name)
                                    .font(.title3)
                                Text("\(workspace.currentFeature)\(workspace.currentContainer != nil ? "(\(workspace.currentContainer!.name))" : "")")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onChange(of: store.selectedWorkspaceID, perform: { newValue in
                        guard let selectedWorkspaceID = newValue, let selectedWorkspace = store.workspace(for: selectedWorkspaceID) else { return }
                        store.selectedWorkspaceID = selectedWorkspaceID
                        store.selectedWorkspace = selectedWorkspace
                        MBoxCommand.sharedInstance.workDir = selectedWorkspace.path
                    })
                    .disabled(workspace.disabled)
                    .contextMenu {
                        Button {
                            showAlert = true
                            alertType = .delete
                            deleteWorkspace = workspace
                        } label: {
                            Image(systemName: "delete.left")
                            Text("删除")
                        }
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "shippingbox")
                    Text("工作空间")
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // 底部按钮
    private var bottomButtonView: some View {
        HStack {
            Spacer()
            Button {
                createWorkspace()
            } label: {
                Image(systemName: "folder.badge.plus")
                Text("新建")
            }
            Spacer()
            Button {
                openWorkspace()
            } label: {
                Image(systemName: "envelope.open")
                Text("打开")
            }
            Spacer()
        }
        .frame(height: 60, alignment: .center)
    }
    
    // MARK: - Event response
    
    // 新建MBox Workspace
    private func createWorkspace() {
        let panel = NSOpenPanel()
        panel.message = "新建MBox Workspace"
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.showsHiddenFiles = false
        panel.canCreateDirectories = true
        panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) { response in
            if response == .OK {
                guard let workDir = panel.url?.path else {
                    alertMsg = "目录URL为空，请重新选择"
                    showAlert = true
                    alertType = .normal
                    return
                }
                if checkMBoxDir(workDir) {
                    alertMsg = "选择的目录已经被MBox管理，请重新选择"
                    showAlert = true
                    alertType = .normal
                    return
                }
                showLoading = true
                DispatchQueue.global().async {
                    MBoxCommand.sharedInstance.workDir = workDir
                    let (_, _) = MBoxCommand.sharedInstance.createWorkspace(of: workDir)
                    addWorkspace(workDir)
                    DispatchQueue.main.async {
                        showLoading = false
                    }
                }
            }
        }
    }
    
    // 打开已经存在的MBox workspace
    private func openWorkspace() {
        let panel = NSOpenPanel()
        panel.message = "打开MBox Workspace"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.showsHiddenFiles = true
        panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) { response in
            if response == .OK {
                guard let workDir = panel.url?.path else {
                    alertMsg = "目录URL为空，请重新选择"
                    showAlert = true
                    alertType = .normal
                    return
                }
                if !checkMBoxDir(workDir) {
                    alertMsg = "选择的目录没有被MBox管理(没有.mbox文件夹)，请重新选择"
                    showAlert = true
                    alertType = .normal
                    return
                }
                if store.existWorkspace(for: workDir) {
                    alertMsg = "列表中已存在该Workspace"
                    showAlert = true
                    alertType = .normal
                    return
                }
                
                debugPrint(workDir)
                showLoading = true
                DispatchQueue.global().async {
                    addWorkspace(workDir)
                    DispatchQueue.main.async {
                        showLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Private methods
    
    private func addWorkspace(_ path: String) {
        let (workspace, error) = MBoxCommand.sharedInstance.workspace(of: path)
        if error != nil {
            showAlert = true
            alertType = .normal
            alertMsg = "出错了\n\(error!)"
            return
        }
        guard let w = workspace else { return }
        DispatchQueue.main.async {
            store.append(w)
        }
    }
    
    // 校验选取目录的正确性
    private func checkMBoxDir(_ path: String) -> Bool {
        let mboxPath = "\(path)/.mbox"
        return FileManager.default.fileExists(atPath: mboxPath)
    }
}

struct WorkspaceListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceListView()
    }
}
