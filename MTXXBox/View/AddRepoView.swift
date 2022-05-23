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
                TextField("请输入分支", text: $branch)
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
