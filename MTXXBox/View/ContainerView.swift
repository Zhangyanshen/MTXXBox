//
//  ContainerView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/27.
//

import SwiftUI

struct ContainerView: View {
    var container: Container?
    var containers: [Container] = []
    var cancelAction: () -> Void = {}
    var okAction: (Container?) -> Void = { _ in }
    @State private var currentContainer: Container?
    
    var body: some View {
        VStack {
            Text("选择Container")
                .font(.title3)
            Divider()
            Menu(currentContainer?.name ?? "") {
                ForEach(containers) { container in
                    Button {
                        currentContainer = container
                    } label: {
                        Text(container.name)
                    }
                }
            }
            .frame(width: 200)
            .modifier(MenuStyle())
            .padding(.vertical, 8)
            Divider()
            HStack {
                Button {
                    cancelAction()
                } label: {
                    Text("取消")
                }
                Button {
                    okAction(currentContainer)
                } label: {
                    Text("确定")
                }
            }
        }
        .frame(width: 300)
        .padding()
    }
}

struct ContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ContainerView()
    }
}
