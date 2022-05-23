//
//  Extension.swift
//  MTXXBox
//
//  Created by zhangyanshen on 2022/5/6.
//

import Foundation
import AppKit

extension String {
    func strip() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func tr(of fromStr: String, with toStr: String) -> String {
        self.replacingOccurrences(of: fromStr, with: toStr)
    }
    
    func regexReplace(with pattern: String) -> String {
        var finalStr = self
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            finalStr = regex.stringByReplacingMatches(in: self, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")
        } catch {
            debugPrint(error)
        }
        return finalStr
    }
    
    var xmlEscaped: String {
      CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault,
                                          self as CFString,
                                          [:] as CFDictionary) as String
    }
}

extension NSColor {
    var cssRGB: String {
      let converted = usingColorSpace(.deviceRGB)!
      let red = converted.redComponent
      let green = converted.greenComponent
      let blue = converted.blueComponent
      
      return "rgb(\(Int(red*255)), \(Int(green*255)), \(Int(blue*255)))"
    }
}

//extension StatusEntry: Identifiable {
//    public var id: String {
//        "\(UUID())"
//    }
//}
