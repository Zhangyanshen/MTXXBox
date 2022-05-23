//
//  Repo.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/4/29.
//

import Foundation
import SwiftyJSON

struct Repo: Identifiable, Codable {
    var id: String
    var name: String
    var url: String
    var type: String
    var branch: String
    var components: [Component]
    var gitInfo: GitInfo
    
    init(_ repo: JSON) {
        id = String(repo["name"].stringValue.hashValue)
        name = repo["name"].stringValue
        branch = repo["branch"].stringValue
        type = repo["type"].stringValue
        url = repo["url"].stringValue
        components = repo["components"].arrayValue.map { Component($0) }
        gitInfo = GitInfo(repo["git_info"])
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

struct Component: Identifiable, Codable {
    var id: String
    var name: String
    var tool: String
    var active: Bool
    
    init(_ json: JSON) {
        name = json["name"].stringValue
        tool = json["tool"].stringValue
        active = json["active"].boolValue
        id = String(name.hashValue & tool.hashValue)
    }
}

struct GitInfo: Codable {
    var clean: Bool
    var commit: String
    var hasConflicts: Bool
    var behindRemote: Int
    var aheadRemote: Int
    
    init(_ json: JSON) {
        clean = json["is_clean"].boolValue
        commit = json["commit"].stringValue
        hasConflicts = json["has_conflicts"].boolValue
        behindRemote = json["behind_remote"].intValue
        aheadRemote = json["ahead_remote"].intValue
    }
}
