//
//  Container.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/27.
//

import Foundation
import SwiftyJSON

struct Container: Identifiable, Codable {
    var id: String
    var name: String
    var tools: [ContainerTool]
    var active: Bool
    
    var bundler: Bool {
        tools.filter { $0.name == "Bundler" }.count > 0
    }
    
    var cocoapods: Bool {
        tools.filter { $0.name == "CocoaPods" }.count > 0
    }
    
    init() {
        id = ""
        name = ""
        tools = []
        active = false
    }
    
    init(_ dic: JSON) {
        id = String(dic["name"].stringValue.hashValue)
        name = dic["name"].stringValue
        tools = dic["tools"].arrayValue.map { ContainerTool($0) }
        let activeTools = dic["tools"].arrayValue.filter { $0["active"].boolValue }
        if activeTools.count > 0 {
            active = true
        } else {
            active = false
        }
    }
}

struct ContainerTool: Codable {
    var name: String
    var active: Bool
    
    init(_ dic: JSON) {
        name = dic["name"].stringValue
        active = dic["active"].boolValue
    }
}
