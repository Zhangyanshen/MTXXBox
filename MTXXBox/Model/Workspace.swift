//
//  Workspace.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/24.
//

import Foundation
import SwiftyJSON

struct Workspace: Identifiable, Equatable, Codable {
    var id: String
    var name: String
    var path: String
    var currentFeature: String
    var features: [String]
    var repos: [Repo]
    var currentContainer: Container?
    var containers: [Container]
    var disabled: Bool = false
    
    var activeContainers: [Container] {
        containers.filter { $0.active }
    }
    
    init(_ json: JSON, features: [String] = [])
    {
        id = String(json["root"].stringValue.hashValue)
        name = json["root"].stringValue.components(separatedBy: "/").last ?? ""
        path = json["root"].stringValue
        currentFeature = json["feature"].stringValue
        self.features = features
        repos = json["repos"].arrayValue.map { Repo($0) }
        containers = json["containers"].arrayValue.map { Container($0) }
        
        // 当前正在使用的Container
        let activeContainers = containers.filter { $0.active }
        if activeContainers.count == 1 {
            self.currentContainer = activeContainers.first
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.path.hashValue == rhs.path.hashValue
    }
}
