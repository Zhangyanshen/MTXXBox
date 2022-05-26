//
//  WebView.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/12.
//

import Foundation
import SwiftUI
import WebKit

struct LocalWebView: NSViewRepresentable {
    var htmlContent: String
    var htmlDir: URL?
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        #if DEBUG
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif
        return webView
    }
    
    func updateNSView(_ webview: WKWebView, context: Context) {
        if let htmlDir = htmlDir {
            webview.loadHTMLString(htmlContent, baseURL: htmlDir)
        }
    }
}
