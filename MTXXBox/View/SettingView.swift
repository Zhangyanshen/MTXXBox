//
//  SettingView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/26.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        TabView {
            Text("通用")
                .frame(width: 400, height: 200, alignment: .top)
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            Text("外观")
                .frame(width: 400, height: 400, alignment: .top)
                .tabItem {
                    Label("外观", systemImage: "eyeglasses")
                }
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
