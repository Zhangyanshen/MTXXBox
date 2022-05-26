//
//  MTXXBoxApp.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/22.
//

import SwiftUI

@main
struct MTXXBoxApp: App {
    @StateObject private var store = Store()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .commands {
            
        }
        Settings {
            SettingView()
        }
    }
}
