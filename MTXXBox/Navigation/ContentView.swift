//
//  ContentView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/22.
//

import SwiftUI
import SwiftShell
import SwiftyJSON

struct ContentView: View {
    @EnvironmentObject var store: Store
    
    @State private var showAlert = false
    @State private var alertMsg = ""
    
    var body: some View {
        NavigationView {
            WorkspaceListView()
            Text("")
            Text("")
        }
        .navigationTitle("MTXXBox")
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                Button {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                } label: {
                    Label("Sidebar", systemImage: "sidebar.left")
                }
            }
        })
        .frame(minWidth: 1000, minHeight: 600)
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text(alertMsg), message: nil, dismissButton: .default(Text("OK"), action: {
                exit(-1)
            }))
        })
        .onAppear {
            checkEnv()
        }
    }
    
    private func checkEnv() {
        let (_, gitError) = MBoxCommand.sharedInstance.checkGit()
        if gitError != nil {
            showAlert = true
            alertMsg = "本机未安装git，请先安装"
            return
        }
        let (_, mboxError) = MBoxCommand.sharedInstance.checkMBox()
        if mboxError != nil {
            showAlert = true
            alertMsg = "本机未安装mbox，请先安装"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        ContentView()
            .preferredColorScheme(.light)
    }
}
