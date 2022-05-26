//
//  AddRepoView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/5.
//

import SwiftUI

struct AddRepoView: View {
    var cancelAction: () -> Void = {}
    var okAction: (String, String) -> Void = { _,_ in }
    
    @State private var url: String = ""
    @State private var branch: String = ""
    @State private var showErrorMsg = false
    @State private var errorMsg: String = ""
    @State private var branches: [String] = []
    @State private var refreshing: Bool = false
    
    var body: some View {
        VStack {
            Text("添加Repo")
                .font(.title3)
            Divider()
                .padding(.vertical, 8)
            HStack {
                Text("URL:")
                TextField("请输入Repo URL", text: $url)
            }
            HStack {
                Text("分支:")
                ZStack {
                    Menu {
                        ForEach(branches, id: \.self) { branch in
                            Button {
                                self.branch = branch
                            } label: {
                                Text(branch)
                            }
                        }
                    } label: {
                        Text(branch)
                    }
                    .modifier(MenuStyle())
                    .disabled(refreshing)
                    
                    if refreshing {
                        ProgressView()
                            .frame(width:20, height: 20)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }

                Button {
                    refreshBranches()
                } label: {
                    Text("刷新")
                }
                .disabled(refreshing)
            }
            Divider()
                .padding(.vertical, 8)
            if showErrorMsg {
                Text(errorMsg)
                    .foregroundColor(.red)
            }
            HStack {
                Button {
                    cancelButtonClick()
                } label: {
                    Text("取消")
                }
                Button {
                    okButtonClick()
                } label: {
                    Text("确认")
                }
            }
        }
        .padding()
        .frame(minWidth: 400)
    }
    
    private func refreshBranches() {
        showErrorMsg = false
        refreshing = true
        DispatchQueue.global().async {
            let (out, error) = MBoxCommand.sharedInstance.gitRemoteBranches(of: url)
            DispatchQueue.main.async {
                refreshing = false
                if out != nil {
                    formatBranches(out!)
                } else {
                    showErrorMsg = true
                    errorMsg = """
                    获取远端分支失败
                    
                    \(error ?? "")
                    """
                }
            }
        }
    }
    
    private func formatBranches(_ out: String) {
        branches = out.components(separatedBy: "\n").map { str in
            guard let lastStr = str.components(separatedBy: "\t").last else { return "" }
            return lastStr.replacingOccurrences(of: "refs/heads/", with: "")
        }.filter({
            $0 != ""
        })
        if branches.count > 0 {
            branch = branches[0]
        }
    }
    
    private func okButtonClick() {
        if url.strip().count == 0 {
            showErrorMsg = true
            errorMsg = "URL不能为空"
            return
        }
        if branch.strip().count == 0 {
            showErrorMsg = true
            errorMsg = "branch不能为空"
            return
        }
        showErrorMsg = false
        okAction(url.strip(), branch.strip())
    }
    
    private func cancelButtonClick() {
        cancelAction()
    }
}

struct AddRepoView_Previews: PreviewProvider {
    static var previews: some View {
        AddRepoView()
    }
}
