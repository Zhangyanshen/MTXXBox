//
//  DeleteFeatureView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/6.
//

import SwiftUI

struct DeleteFeatureView: View {
    var currentFeature: String = ""
    var features: [String] = []
    var cancelAction: () -> Void = {}
    var okAction: (String, Bool, Bool) -> Void = { _,_,_ in }
    
    @State private var errorMsg: String?
    @State private var selectFeature: String = ""
    
    @State private var removeCache: Bool = false
    @State private var force: Bool = false
    
    var body: some View {
        VStack {
            Text("请选择要删除的Feature")
                .font(.title3)
            Divider()
            HStack {
                Menu(selectFeature) {
                    ForEach(features, id: \.self) { feature in
                        Button {
                            selectFeature = feature
                        } label: {
                            Text(feature)
                        }
                    }
                }
                .frame(width: 200)
            }
            .modifier(MenuStyle())
            .padding(.vertical, 8)
            HStack {
                Toggle("删除缓存", isOn: $removeCache)
                Toggle("强制删除(未提交的commit会丢失)", isOn: $force)
            }
            Divider()
            if errorMsg != nil {
                Text(errorMsg!)
                    .foregroundColor(.red)
            }
            HStack {
                Button {
                    cancelAction()
                } label: {
                    Text("取消")
                }
                Button {
                    deleteFeature()
                } label: {
                    Text("确认")
                }
            }
        }
        .padding()
        .frame(minWidth: 350)
    }
    
    private func deleteFeature() {
        if selectFeature == "" {
            errorMsg = "请选择要删除的Feature"
            return
        }
        if selectFeature == "FreeMode" {
            errorMsg = "不能删除FreeMode"
            return
        }
        if selectFeature == currentFeature {
            errorMsg = "不能删除当前Feature，请先切换到其他Feature"
            return
        }
        okAction(selectFeature, removeCache, force)
    }
}

struct DeleteFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteFeatureView()
    }
}
