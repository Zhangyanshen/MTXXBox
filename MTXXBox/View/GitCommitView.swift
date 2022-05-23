//
//  GitCommitView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/17.
//

import SwiftUI

struct GitCommitView: View {
    var cancelAction: () -> Void = {}
    var okAction: (String, Bool) -> Void = { _,_ in }
    
    @State private var commitMsg: String = ""
    @State private var pushCommit: Bool = false
    
    var body: some View {
        VStack {
            Text("提交")
                .font(.title3)
            TextEditor(text: $commitMsg)
                .border(.separator)
            Toggle(isOn: $pushCommit) {
                Text("立即推送到远端")
            }
            HStack {
                Button {
                    cancelAction()
                } label: {
                    Text("取消")
                }
                Button {
                    okAction(commitMsg, pushCommit)
                } label: {
                    Text("确定")
                }
                .disabled(commitMsg.count == 0)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
    
    
}

struct GitCommitView_Previews: PreviewProvider {
    static var previews: some View {
        GitCommitView()
    }
}
