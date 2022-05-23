//
//  RepoListView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/29.
//

import SwiftUI
import SwiftyJSON

struct RepoListView: View {
    @EnvironmentObject var store: Store
    
    @State private var showCreateFeature = false
    @State private var showImportFeature = false
    @State private var showDeleteFeature = false
    @State private var showSwitchFeature = false
    
    @State private var showAddRepo = false
    @State private var showLoading = false
    @State private var loadingTip = "请稍后..."
    @State private var loadingFinished = false
    @State private var log = ""
    @State private var showSelectContainerView = false
    @State private var currentContainer: Container?
    
    @State private var showAlert = false
    @State private var alertMsg = ""
    @State private var alertType: AlertType = .normal
    
    @State private var selectedRepoId: Repo.ID?
    
    private var activeContainers: [Container] {
        store.selectedWorkspace?.activeContainers ?? []
    }
    
    private var navTitle: String {
        store.selectedWorkspace?.name ?? ""
    }
    
    private var navSubTitle: String {
        var title = store.selectedWorkspace?.currentFeature ?? ""
        if store.selectedWorkspace?.currentContainer != nil {
            title += "(\(store.selectedWorkspace?.currentContainer?.name ?? ""))"
        }
        return title
    }
    
    // MARK: - View
    
    var body: some View {
        VStack {
            listView
            Spacer()
            bottomView
        }
        .frame(minWidth: 220)
        .navigationTitle(navTitle)
        .navigationSubtitle(navSubTitle)
        .toolbar {
            if store.selectedWorkspaceID != nil {
                ProjectToolBar(repos: store.selectedWorkspace?.repos ?? []) {
                    refreshWorkspace(false)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshState"), object: nil)
                    }
                }
            }
        }
        .contextMenu { listMenu }
        .sheet(isPresented: $showLoading) {
            LoadingView(finished: loadingFinished, tip: loadingTip, log: $log) {
                showLoading = false
                log = ""
            }
        }
        .sheet(isPresented: $showSelectContainerView, content: {
            ContainerView(container: currentContainer,
                          containers: activeContainers,
                          cancelAction: { showSelectContainerView = false },
                          okAction: changeContainer)
        })
        .sheet(isPresented: $showAddRepo, content: {
            AddRepoView(cancelAction: { showAddRepo = false },
                        okAction: { addRepo($0, $1)})
        })
        .sheet(isPresented: $showCreateFeature, content: {
            CreateFeatureView(cancelAction: { showCreateFeature = false },
                              okAction: { createFeature($0, $1) })
        })
        .sheet(isPresented: $showImportFeature, content: {
            ImportFeatureView(cancelAction: { showImportFeature = false },
                              okAction: { importFeature($0, keepChanged: $1, checkBranchExists: $2, recurseSubmodules: $3) })
        })
        .sheet(isPresented: $showDeleteFeature, content: {
            DeleteFeatureView(currentFeature: store.selectedWorkspace?.currentFeature ?? "",
                              features: store.selectedWorkspace?.features ?? [],
                              cancelAction: { showDeleteFeature = false },
                              okAction: { deleteFeature($0, removeCache: $1, force: $2) })
        })
        .sheet(isPresented: $showSwitchFeature, content: {
            SwitchFeatureView(currentFeature: store.selectedWorkspace?.currentFeature ?? "",
                              features: store.selectedWorkspace?.features ?? [],
                              cancelAction: { showSwitchFeature = false },
                              okAction: { switchFeature($0) })
        })
        .onAppear {
            currentContainer = store.selectedWorkspace?.currentContainer
            if currentContainer == nil && activeContainers.count > 1 {
                showSelectContainerView = true
            }
        }
        .alert(isPresented: $showAlert) {
            switch alertType {
            case .normal:
                return Alert(title: Text(alertMsg), dismissButton: .default(Text("OK")))
            case .delete:
                return Alert(title: Text(alertMsg), message: nil, primaryButton: .destructive(Text("确定"), action: {
                    
                }), secondaryButton: .cancel(Text("取消"), action: {
                    
                }))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            refreshWorkspace(false)
        }
    }
    
    private var listView: some View {
        List {
            Section {
                ForEach(store.selectedWorkspace?.repos ?? []) { repo in
                    NavigationLink(tag: repo.id, selection: $selectedRepoId) {
                        RepoView(repo: repo)
                    } label: {
                        RepoItem(repo: repo)
                    }
                    .contextMenu { menu(of: repo) }
                }
            } header: {
                HStack {
                    Image(systemName: "server.rack")
                    Text("仓库")
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var bottomView: some View {
        VStack {
            if store.selectedWorkspaceID != nil && store.selectedWorkspace?.currentContainer != nil {
                HStack {
                    if store.selectedWorkspace?.currentContainer!.bundler ?? false
                    {
                        Spacer()
                        Button {
                            bundleInstall()
                        } label: {
                            Text("bundle install")
                        }
                    }
                    if
                        store.selectedWorkspace?.currentContainer!.cocoapods ?? false
                    {
                        Spacer()
                        Button {
                            podInstall()
                        } label: {
                            Text("pod install")
                        }
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 60)
    }
    
    private var listMenu: some View {
        VStack {
            // 添加Repo
            Group {
                Button {
                    showAddRepo = true
                } label: {
                    Image(systemName: "plus")
                    Text("添加Repo")
                }
            }
            // 新建、删除Feature
            Group {
                Divider()
                Button {
                    showCreateFeature = true
                } label: {
                    Image(systemName: "externaldrive.badge.plus")
                    Text("新建Feature")
                }
                Button {
                    showDeleteFeature = true
                } label: {
                    Image(systemName: "delete.left")
                    Text("删除Feature")
                }
            }
            // 导入、导出Feature
            Group {
                Divider()
                Button {
                    exportFeature()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                    Text("导出Feature")
                }
                Button {
                    showImportFeature = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                    Text("导入Feature")
                }
            }
            // 切换Feature
            if store.selectedWorkspace?.features.count ?? 1 > 1 {
                Group {
                    Divider()
                    Button {
                        showSwitchFeature = true
                    } label: {
                        Image(systemName: "switch.2")
                        Text("切换Feature")
                    }
                }
            }
            // 切换Container
            if store.selectedWorkspace?.containers.count ?? 0 > 1 {
                Group {
                    Divider()
                    Button {
                        showSelectContainerView = true
                    } label: {
                        Image(systemName: "switch.2")
                        Text("切换Container")
                    }
                }
            }
            // 刷新
            Group {
                Divider()
                Button {
                    refreshWorkspace()
                } label: {
                    Image(systemName: "arrow.clockwise")
                    Text("刷新")
                }
            }
            // MBox Go
            Group {
                Divider()
                Button {
                    mboxGo()
                } label: {
                    Image(systemName: "shippingbox")
                    Text("MBox Go")
                }

            }
        }
    }
    
    private func menu(of repo: Repo) -> some View {
        VStack {
            if repo.components.count > 0 {
                Group {
                    Button {
                        active(repo)
                    } label: {
                        Image(systemName: "bolt")
                        Text("激活")
                    }
                    Button {
                        deactive(repo)
                    } label: {
                        Image(systemName: "bolt.slash")
                        Text("取消激活")
                    }
                }
            }
            Divider()
            Button {
                debugPrint("create tag")
            } label: {
                Image(systemName: "tag")
                Text("创建Tag")
            }
            Divider()
            Button {
                deleteRepo(repo)
            } label: {
                Image(systemName: "delete.left")
                Text("删除Repo")
            }
        }
    }
    
    private var currentBranch: String {
        guard let repos = store.selectedWorkspace?.repos, !repos.isEmpty else { return "" }
        return repos.first?.branch ?? ""
    }
    
    // MARK: - Repo
    
    // 添加Repo
    private func addRepo(_ url: String, _ branch: String) {
        showAddRepo = false
        showLoading = true
        DispatchQueue.global().async {
            let (_, _) = MBoxCommand.sharedInstance.addRepo(url, branch: branch)
            refreshWorkspace(false)
            DispatchQueue.main.async {
                showLoading = false
            }
        }
    }
    
    // 从当前Feature中移除repo
    private func deleteRepo(_ repo: Repo) {
        showLoading = true
        DispatchQueue.global().async {
            let (_, error) = MBoxCommand.sharedInstance.deleteRepo(repo.name)
            DispatchQueue.main.async {
                showLoading = false
                if error != nil {
                    showAlert = true
                    alertMsg = """
                    删除Repo失败
                    
                    \(error!)
                    """
                    return
                }
                refreshWorkspace(false)
            }
        }
    }
    
    // MARK: - Feature
    
    // 导出feature
    private func exportFeature() {
        let panel = NSSavePanel()
        panel.message = "导出Feature"
        panel.nameFieldStringValue = "feature.json"
        panel.showsHiddenFiles = false
        panel.isExtensionHidden = false
        panel.allowedFileTypes = ["json"]
        panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) { response in
            if response == .OK {
                guard let url = panel.url else {
                    alertMsg = "目录URL为空，请重新选择"
                    showAlert = true
                    return
                }
                showLoading = true
                DispatchQueue.global().async {
                    let (output, error) = MBoxCommand.sharedInstance.exportFeature()
                    showLoading = false
                    DispatchQueue.main.async {
                        if error == nil {
                            do {
                                try output!.write(to: url, atomically: true, encoding: .utf8)
                                showAlert = true
                                alertMsg = "导出Feature成功"
                            } catch {
                                showAlert = true
                                alertMsg = "导出Feature失败，请重试！\n\n\(error)"
                            }
                        } else {
                            showAlert = true
                            alertMsg = """
                            导出Feature失败
                            
                            \(error!)
                            """
                        }
                    }
                }
            }
        }
    }
    
    // 导入feature
    private func importFeature(_ feature: String,
                               keepChanged: Bool,
                               checkBranchExists: Bool,
                               recurseSubmodules: Bool)
    {
        showImportFeature = false
        showLoading = true
        DispatchQueue.global().async {
            let (_, error) = MBoxCommand.sharedInstance.importFeature(feature,
                                                     keepChanges: keepChanged,
                                                     checkBranchExists: checkBranchExists,
                                                     recurseSubmodules: recurseSubmodules)
            DispatchQueue.main.async {
                showLoading = false
                showAlert = true
                if error == nil {
                    alertMsg = "导入Feature成功"
                } else {
                    alertMsg = """
                    导入Feature失败，请重试
                    
                    \(error!)
                    """
                }
            }
        }
    }
    
    // 新建feature
    private func createFeature(_ name: String, _ prefix: String) {
        showCreateFeature = false
        showLoading = true
        DispatchQueue.global().async {
            let (_, error) = MBoxCommand.sharedInstance.createFeature(name, prefix: prefix.count == 0 ? nil : prefix)
            DispatchQueue.main.async {
                showLoading = false
                if error != nil {
                    showAlert = true
                    alertMsg = """
                    新建Feature失败
                    
                    \(error!)
                    """
                    return
                }
                refreshWorkspace(false)
            }
        }
    }
    
    // 删除feature
    private func deleteFeature(_ feature: String,
                               removeCache: Bool,
                               force: Bool)
    {
        showDeleteFeature = false
        showLoading = true
        DispatchQueue.global().async {
            let (_, error) = MBoxCommand.sharedInstance.deleteFeature(feature, includeRepo: removeCache, force: force)
            DispatchQueue.main.async {
                showLoading = false
                showAlert = true
                if error == nil {
                    alertMsg = "删除Feature:`\(feature)`成功"
                    refreshWorkspace(false)
                } else {
                    alertMsg = """
                    删除Feature:`\(feature)`失败
                    
                    \(error!)
                    """
                }
            }
        }
    }
    
    // 切换Feature
    private func switchFeature(_ feature: String) {
        showLoading = true
        showSwitchFeature = false
        DispatchQueue.global().async {
            let (_, error) = MBoxCommand.sharedInstance.startFeature(feature)
            DispatchQueue.main.async {
                showLoading = false
                if error != nil {
                    showAlert = true
                    alertMsg = """
                    切换Feature失败
                    
                    \(error!)
                    """
                    return
                }
                refreshWorkspace(false)
            }
        }
    }
    
    // MARK: - Container
    
    // 切换Container
    private func changeContainer(_ container: Container?) {
        if store.selectedWorkspace?.currentContainer?.name == container?.name {
            return
        }
        guard let c = container else { return }
        currentContainer = c
        showLoading = true
        DispatchQueue.global().async {
            let (repos, error) = MBoxCommand.sharedInstance.changeContainer(c.name)
            if error != nil {
                return
            }
            // 更新UI
            DispatchQueue.main.async {
                store.selectedWorkspace?.repos = repos!
                showLoading = false
            }
        }
    }
    
    // MARK: - Workspace
    
    // 刷新当前选中的Workspace
    private func refreshWorkspace(_ loading: Bool = true) {
        if let workDir = MBoxCommand.sharedInstance.workDir {
            if loading {
                showLoading = true
            }
            DispatchQueue.global().async {
                let (workspace, error) = MBoxCommand.sharedInstance.workspace(of: workDir)
                DispatchQueue.main.async {
                    if loading {
                        showLoading = false
                    }
                    if error == nil {
                        store.selectedWorkspace = workspace!
                    } else {
                        showAlert = true
                        alertMsg = error!
                    }
                }
            }
        }
    }
    
    // MARK: - Active/Deactive
    
    private func active(_ repo: Repo) {
        showLoading = true
        DispatchQueue.global().async {
            let (_, error) = MBoxCommand.sharedInstance.active(component: repo.name)
            DispatchQueue.main.async {
                showLoading = false
                if error == nil {
                    refreshWorkspace(false)
                } else {
                    showAlert = true
                    alertMsg = """
                    激活`\(repo.name)`失败
                    
                    \(error!)
                    """
                }
            }
        }
    }
    
    private func deactive(_ repo: Repo) {
        showLoading = true
        DispatchQueue.global().async {
            let (_, error) = MBoxCommand.sharedInstance.deactive(component: repo.name)
            DispatchQueue.main.async {
                showLoading = false
                if error == nil {
                    refreshWorkspace(false)
                } else {
                    showAlert = true
                    alertMsg = """
                    不激活`\(repo.name)`失败
                    
                    \(error!)
                    """
                }
            }
        }
    }
    
    // MARK: - Install
    
    private func bundleInstall() {
        showLoading = true
        DispatchQueue.global().async {
            let (_, error) = MBoxCommand.sharedInstance.bundleInstall()
            DispatchQueue.main.async {
                showAlert = true
                showLoading = false
                if error == nil {
                    alertMsg = "bundle install成功"
                } else {
                    alertMsg = """
                    bundle install失败
                    
                    \(error!)
                    """
                }
            }
        }
    }
    
    private func podInstall() {
        showLoading = true
        loadingTip = "请稍后..."
        loadingFinished = false
        MBoxCommand.sharedInstance.podInstallAsync { out in
            log += "\(out)\n"
        } stderror: { error in
            log += "\(error)\n"
        } complete: { success in
            loadingFinished = true
            if success {
                loadingTip = "pod install成功"
            } else {
                loadingTip = "pod install失败"
            }
        }
    }
    
    // MARK: - Go
    
    private func mboxGo() {
        let (_, error) = MBoxCommand.sharedInstance.mboxGo()
        if error != nil {
            showAlert = true
            alertMsg = """
            打开MBox Workspace失败

            \(error!)
            """
        }
    }
}

struct RepoItem: View {
    var repo: Repo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(repo.name)
                    .font(.title3)
                Text("\(repo.type):\(repo.branch)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ForEach(repo.components) { component in
                    HStack {
                        Text(component.active ? "+" : "-")
                            .foregroundColor(component.active ? .green : .red)
                        Text("[\(component.tool)]")
                        Text(component.name)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                HStack {
                    Text("↳\(repo.gitInfo.behindRemote)")
                    Text("↰\(repo.gitInfo.aheadRemote)")
                    if !(repo.gitInfo.clean) {
                        Text("*")
                            .foregroundColor(.red)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                Spacer()
            }
            .lineLimit(1)
            Spacer()
        }
        .padding(4)
    }
}

struct RepoListView_Previews: PreviewProvider {
    static var previews: some View {
        RepoListView()
    }
}
