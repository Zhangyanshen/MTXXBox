//
//  ProjectToolBar.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/22.
//

import SwiftUI

// 选中项目后，toolbar按钮
struct ProjectToolBar: View {
    var repos: [Repo]
    var refreshAction: () -> Void
    
    private let queue = DispatchQueue(label: "com.mtxx.box.pull.serial")
    
    @State private var count = 0
        
    @State private var showAlert = false
    @State private var alertMsg = ""
    
    @State private var showLoading = false
    @State private var loadingTip = "请稍后..."
    @State private var loadingFinished = false
    @State private var log = ""
    
    @State private var showCommitView = false
    
    var body: some View {
        HStack {
            Button {
                stashAll()
            } label: {
                Text("暂存")
            }
            Button {
                showCommitView.toggle()
            } label: {
                Text("提交")
            }
            Button {
                gitPull()
            } label: {
                Text("拉取")
            }
            Button {
                gitPush()
            } label: {
                Text("推送")
            }
            Button {
                gitFetch()
            } label: {
                Text("抓取")
            }
            Button {
                openInTerminal()
            } label: {
                Text("从终端打开")
            }
            Button {
                openInFinder()
            } label: {
                Text("在Finder中显示")
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertMsg), message: nil, dismissButton: .default(Text("OK"), action: {
                showAlert = false
            }))
        }
        .sheet(isPresented: $showLoading) {
            LoadingView(finished: loadingFinished, tip: loadingTip, log: $log) {
                showLoading = false
                log = ""
            }
        }
        .sheet(isPresented: $showCommitView) {
            GitCommitView {
                showCommitView.toggle()
            } okAction: { commitMsg, pushCommit in
                gitCommit(commitMsg, pushCommit: pushCommit)
            }
        }
    }
    
    // MARK: - Git
    
    // 暂存
    private func stashAll() {
        showLoading = true
        queue.async {
            let (_, error) = MBoxCommand.sharedInstance.gitStashAll()
            showLoading = false
            if error == nil {
                refreshAction()
            } else {
                showAlert = true
                alertMsg = """
                暂存失败
                
                \(error!)
                """
            }
        }
    }
    
    // 提交
    private func gitCommit(_ commitMsg: String, pushCommit: Bool) {
        showLoading = true
        loadingTip = "git提交中..."
        loadingFinished = false
        MBoxCommand.sharedInstance.gitCommitAsync(commitMsg) { out in
            print("stdout:\(out)")
            log += out
        } stderror: { error in
            print("stderror:\(error)")
            log += error
        } complete: { success in
            if pushCommit {
                log += "git提交成功\n"
                gitPush(true)
            } else {
                loadingFinished = true
                if success {
                    loadingTip = "git提交成功"
                } else {
                    loadingTip = "git提交失败"
                }
                refreshAction()
            }
            showCommitView.toggle()
        }
    }
    
    // 推送
    private func gitPush(_ fromCommit: Bool = false) {
        showLoading = true
        loadingTip = "git推送中..."
        loadingFinished = false
        var successCount = 0
        queue.async {
            for repo in repos {
                gitPushRepo(repo, fromCommit: true, successCount: &successCount)
            }
            refreshAction()
        }
    }
    
    // 推送单个仓库
    private func gitPushRepo(_ repo: Repo, fromCommit: Bool, successCount: inout Int) {
        count += 1
        log += "[\(repo.name)]\n"
        
        guard let workDir = MBoxCommand.sharedInstance.workDir else { return }
        
        MBoxCommand.sharedInstance.workDir = "\(workDir)/\(repo.name)"
        
        let (out, error) = MBoxCommand.sharedInstance.gitPush(of: repo.branch)
        
        if out != nil {
            log += " \(out!)\n"
            successCount += 1
        }
        if error != nil {
            log += " \(error!)\n"
        }
        if count >= repos.count {
            count = 0
            loadingFinished = true
            loadingTip = successCount >= repos.count ? "git推送成功" : "git推送失败"
        }
        MBoxCommand.sharedInstance.workDir = workDir
    }
    
    // 拉取
    private func gitPull() {
        showLoading = true
        loadingTip = "git拉取中..."
        loadingFinished = false
        var successCount = 0
        queue.async {
            for repo in repos {
                gitPullRepo(repo, successCount: &successCount)
            }
            refreshAction()
        }
    }
    
    // 拉取单个仓库
    private func gitPullRepo(_ repo: Repo, successCount: inout Int) {
        count += 1
        log += "[\(repo.name)]\n"
        
        guard let workDir = MBoxCommand.sharedInstance.workDir else { return }
        
        MBoxCommand.sharedInstance.workDir = "\(workDir)/\(repo.name)"
                
        let (out, error) = MBoxCommand.sharedInstance.gitPull(of: repo.branch)
        
        if out != nil {
            log += " \(out!)\n"
            successCount += 1
        }
        if error != nil {
            log += " \(error!)\n"
        }
        if count >= repos.count {
            count = 0
            loadingFinished = true
            loadingTip = successCount >= repos.count ? "git拉取成功" : "git拉取失败"
        }
        MBoxCommand.sharedInstance.workDir = workDir
    }
    
    // 抓取
    private func gitFetch() {
        showLoading = true
        loadingTip = "git抓取中..."
        loadingFinished = false
        MBoxCommand.sharedInstance.gitFetchAsync { out in
            print("stdout:\(out)")
            log += out
        } stderror: { error in
            print("stderror:\(error)")
            log += error
        } complete: { success in
            loadingFinished = true
            if success {
                loadingTip = "git抓取成功"
            } else {
                loadingTip = "git抓取失败"
            }
        }
    }
    
    // MARK: - Other
    
    private func openInTerminal() {
        let (_, error) = MBoxCommand.sharedInstance.openInTerminal()
        if error != nil {
            showAlert = true
            alertMsg = """
            从终端打开失败
            
            \(error!)
            """
        }
    }
    
    private func openInFinder() {
        let (_, error) = MBoxCommand.sharedInstance.openInFinder()
        if error != nil {
            showAlert = true
            alertMsg = """
            在Finder中打开失败
            
            \(error!)
            """
        }
    }
}

struct ProjectToolBar_Previews: PreviewProvider {
    static var previews: some View {
        ProjectToolBar(repos: [], refreshAction: {})
    }
}
