//
//  M3UParser.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import Foundation

struct M3UParser {
    static func parse(_ text: String) -> [TVChannel] {
        var channels: [TVChannel] = []
        // 处理某些 M3U 文件开头的隐藏字符 (BOM)
        let cleanText = text.replacingOccurrences(of: "\u{FEFF}", with: "")
        let lines = cleanText.components(separatedBy: .newlines)
        
        var currentName = ""
        var currentLogo = ""
        var currentGroup = "未分类"
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }
            
            if trimmedLine.hasPrefix("#EXTINF:") {
                // 1. 提取频道名：找到最后一个逗号
                if let commaIndex = trimmedLine.lastIndex(of: ",") {
                    let namePart = trimmedLine[trimmedLine.index(after: commaIndex)...]
                    currentName = namePart.trimmingCharacters(in: .whitespaces)
                }
                
                // 2. 使用更稳健的正则方式提取标签内容
                currentLogo = self.extractTagValue(from: trimmedLine, tagName: "tvg-logo")
                // 重点：尝试多个可能的组名标签
                let group = self.extractTagValue(from: trimmedLine, tagName: "group-title")
                currentGroup = group.isEmpty ? "其他" : group
                
            } else if trimmedLine.hasPrefix("http") {
                if !currentName.isEmpty {
                    let channel = TVChannel(
                        name: currentName,
                        group: currentGroup,
                        logo: currentLogo,
                        streamUrl: trimmedLine,
                        
                    )
                    channels.append(channel)
                }
                // 重置，防止数据污染到下一行
                currentName = ""
                currentLogo = ""
                currentGroup = "其他"
            }
        }
        return channels
    }
    
    private static func extractTagValue(from text: String, tagName: String) -> String {
        // 匹配 tagName="value" 的模式
        let pattern = "\(tagName)=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return "" }
        
        let nsString = text as NSString
        let results = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = results, match.numberOfRanges > 1 {
            return nsString.substring(with: match.range(at: 1))
        }
        return ""
    }
}
