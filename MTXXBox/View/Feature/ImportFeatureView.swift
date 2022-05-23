//
//  ImportFeatureView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/6.
//

import SwiftUI

struct ImportFeatureView: View {
    var cancelAction: () -> Void = {}
    var okAction: (String, Bool, Bool, Bool) -> Void = { _,_,_,_ in }
    
    @State private var jsonFilePath: String?
    @State private var keepChanged = false
    @State private var checkBranchExists = false
    @State private var recurseSubmodules = false
    @State private var errorMsg = ""
    
    var body: some View {
        VStack {
            Text("导入Feature")
                .font(.title3)
            Divider()
            HStack {
                Button {
                    chooseJsonFile()
                } label: {
                    Text("选择json文件")
                }
                Text(jsonFilePath ?? "请选择json文件")
                Spacer()
            }
            .padding(.vertical, 8)
            HStack {
                Toggle("保留本地更改", isOn: $keepChanged)
                Toggle("检查分支是否存在", isOn: $checkBranchExists)
                Toggle("初始化submodules", isOn: $recurseSubmodules)
            }
            .padding(.vertical, 8)
            Divider()
            Text(errorMsg)
                .foregroundColor(.red)
            HStack {
                Button {
                    cancelAction()
                } label: {
                    Text("取消")
                }
                Button {
                    importFeature()
                } label: {
                    Text("确认")
                }
            }
        }
        .padding()
        .frame(minWidth: 450)
    }
    
    private func chooseJsonFile() {
        let panel = NSOpenPanel()
        panel.message = "选择json文件"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.showsHiddenFiles = false
        panel.allowedFileTypes = ["json"]
        panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) { response in
            if response == .OK {
                guard let url = panel.url else {
                    errorMsg = "选择的URL为空，请重新选择"
                    return
                }
                errorMsg = ""
                jsonFilePath = url.path
            }
        }
    }
    
    private func importFeature() {
        if jsonFilePath == nil {
            errorMsg = "请先选择json文件"
            return
        }
        if !FileManager.default.fileExists(atPath: jsonFilePath!) {
            errorMsg = "文件`\(jsonFilePath!)`不存在，请重新选择"
            return
        }
        do {
            errorMsg = ""
            let jsonStr = try String(contentsOf: URL(fileURLWithPath: jsonFilePath!))
            okAction(jsonStr, keepChanged, checkBranchExists, recurseSubmodules)
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

struct ImportFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        ImportFeatureView()
    }
}
