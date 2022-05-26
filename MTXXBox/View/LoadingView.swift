//
//  LoadingView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/23.
//

import SwiftUI

struct LoadingView: View {
    var finished: Bool = false
    var tip: String = "请稍后..."
    @Binding var log: String
    var closeAction: () -> Void = {}
    
    @State private var showLog = false
    
    var body: some View {
        VStack {
            if !finished {
                ProgressView()
                    .padding(.top, 16)
                    .padding(8)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            Text(tip)
                .foregroundColor(.primary)
                .font(.title3)
                .fontWeight(.bold)
                .padding(8)
                .padding(.top, finished ? 16 : 0)
            if !showLog {
                HStack {
                    Button {
                        showLog.toggle()
                    } label: {
                        HStack {
                            Image(systemName: showLog ? "chevron.down" : "chevron.right")
                            Text("显示完整输出")
                                .foregroundColor(.secondary)
                                .font(.body)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            if showLog {
                TextEditor(text: .constant(log))
                    .frame(minHeight: 200)
                    .font(.body)
                    .foregroundColor(.cyan)
                    .border(.separator)
                    .padding(4)
            }
            HStack {
                Spacer()
                Button {
                    closeAction()
                } label: {
                    Text("关闭")
                }
                .disabled(!finished)
            }
            .padding(.bottom, 8)
            .padding(.trailing, 8)
        }
        .frame(minWidth: showLog ? 400 : 200)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(log: .constant(""))
        LoadingView(log: .constant(""))
            .preferredColorScheme(.light)
    }
}
