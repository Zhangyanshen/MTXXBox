//
//  CreateFeatureView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/5.
//

import SwiftUI

struct CreateFeatureView: View {
    var cancelAction: () -> Void = {}
    var okAction: (String, String) -> Void = { _,_ in }
    
    @State private var name = ""
    @State private var prefixOn = false
    @State private var prefix = ""
    
    var body: some View {
        VStack {
            Text("新建Feature")
                .font(.title3)
            Divider()
                .padding(.vertical, 8)
            HStack {
                Text("Feature名:")
                TextField("请输入Feature名", text: $name)
            }
            HStack {
                Toggle("前缀", isOn: $prefixOn)
                TextField("请输入前缀", text: $prefix)
                    .disabled(!prefixOn)
            }
            HStack {
                Button {
                    cancelAction()
                } label: {
                    Text("取消")
                }
                Button {
                    okAction(name, prefix)
                } label: {
                    Text("确定")
                }
            }
        }
        .padding()
        .frame(minWidth: 400)
    }
}

struct CreateFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        CreateFeatureView()
    }
}
