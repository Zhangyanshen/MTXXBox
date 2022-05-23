//
//  SwitchFeatureView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/7.
//

import SwiftUI

struct SwitchFeatureView: View {
    var currentFeature: String = ""
    var features: [String] = []
    var cancelAction: () -> Void = {}
    var okAction: (String) -> Void = { _ in }
    
    @State private var errorMsg: String?
    @State private var selectFeature: String = ""
    
    var body: some View {
        VStack {
            Text("请选择要切换的Feature")
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
                    switchFeature()
                } label: {
                    Text("确认")
                }
            }
        }
        .padding()
        .frame(minWidth: 300)
    }
    
    private func switchFeature() {
        if selectFeature == "" {
            errorMsg = "请选择Feature"
            return
        }
        if selectFeature == currentFeature {
            errorMsg = "当前正处于Feature:`\(currentFeature)`"
            return
        }
        okAction(selectFeature)
    }
}

struct SwitchFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SwitchFeatureView()
    }
}
