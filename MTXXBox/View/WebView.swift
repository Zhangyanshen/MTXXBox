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
        updateColors(webview)
        if let htmlDir = htmlDir {
            webview.loadHTMLString(htmlContent, baseURL: htmlDir)
        }
    }
    
    func updateColors(_ webView: WKWebView) {
        let savedAppearance = NSAppearance.currentDrawing()
        
        defer {
          NSAppearance.current = savedAppearance
        }
        
        NSAppearance.current = webView.effectiveAppearance
        
        let names = [
            "addBackground",
            "background",
            "blameBorder",
            "blameStart",
            "buttonActiveBorder",
            "buttonActiveGrad1",
            "buttonActiveGrad2",
            "buttonBorder",
            "buttonGrad1",
            "buttonGrad2",
            "deleteBackground",
            "divider",
            "heading",
            "hunkBottomBorder",
            "hunkTopBorder",
            "jumpActive",
            "jumpHoverBackground",
            "leftBackground",
            "shadow",
            "lineNumColor"
        ]
        setColor(for: webView, name: "textColor", color: .textColor)
        setColor(for: webView, name: "textBackground", color: .textBackgroundColor)
        setColor(for: webView, name: "underPageBackgroundColor", color: .underPageBackgroundColor)
        
        for name in names {
            if let color = NSColor(named: name) {
                setColor(for: webView, name: name, color: color)
            }
        }
    }
    
    private func setColor(for webView: WKWebView,
                          name: String,
                          color: NSColor)
    {
        setDocumentProperty(for: webView, property: "--\(name)", value: color.cssRGB)
    }
    
    private func setDocumentProperty(for webView: WKWebView,
                                     property: String,
                                     value: String)
    {
        webView.evaluateJavaScript("document.documentElement.style.setProperty('\(property)', '\(value)')") { _, error in
            if error != nil {
                print("修改颜色失败:\(error!)")
            } else {
                print("修改颜色成功")
            }
        }
    }
}
