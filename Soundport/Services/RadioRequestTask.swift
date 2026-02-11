//
//  RadioRequestTask.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/11.
//

import Foundation

enum RadioRequestTask {
    case hot(limit: Int)
    case region(province: String)
    case tag(name: String)
    case search(query: String)

    // 自动映射 API 路径
    var path: String {
        switch self {
        case .hot: return "/stations/bycountrycodeexact/CN" // 国家精确匹配
        default: return "/stations/search" // 其他全部走通用搜索，兼容性最好
        }
    }

    // 自动构建参数
    var parameters: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "clickcount"),
            URLQueryItem(name: "reverse", value: "true")
        ]
        
        switch self {
        case .hot(let limit):
            items.append(URLQueryItem(name: "limit", value: "\(limit)"))
        case .region(let province):
            items.append(URLQueryItem(name: "state", value: province))
            items.append(URLQueryItem(name: "countrycode", value: "CN"))
        case .tag(let name):
            items.append(URLQueryItem(name: "tag", value: name))
            items.append(URLQueryItem(name: "countrycode", value: "CN"))
        case .search(let query):
            items.append(URLQueryItem(name: "name", value: query))
        }
        return items
    }
}
