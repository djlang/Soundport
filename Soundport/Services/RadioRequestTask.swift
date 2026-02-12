//
//  RadioRequestTask.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/11.
//

import Foundation

enum RadioTask {
    case hot(limit: Int, offset: Int)
    case region(state: String, limit: Int, offset: Int)
    case tag(name: String, limit: Int, offset: Int)
    case national
    case country(code: String, limit: Int, offset: Int)
    case search(query: String, limit: Int, offset: Int)

    /// 映射 API 路径
    var path: String {
        switch self {
        case .hot: return "/stations/bycountrycodeexact/CN"
        case .region(let state, _, _):
            // 如果是港澳台，直接走国家代码精确匹配路径
            if ["香港", "台湾", "澳门", "HK", "TW", "MO"].contains(state) {
                let code = convertToCode(state)
                return "/stations/bycountrycodeexact/\(code)"
            }
            return "/stations/search"
        default: return "/stations/search"
        }
    }
    
    /// 辅助方法：统一转换代码
    private func convertToCode(_ state: String) -> String {
        switch state {
        case "香港": return "HK"
        case "台湾": return "TW"
        case "澳门": return "MO"
        default: return state // 如果已经是代码则直接返回
        }
    }

    /// 映射查询参数
    var parameters: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "clickcount"),
            URLQueryItem(name: "reverse", value: "true")
        ]
        
        switch self {
        case .hot(let limit, let offset):
            items.append(contentsOf: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ])
            
        case .region(let state, let limit, let offset):
            if ["香港", "台湾", "澳门", "HK", "TW", "MO"].contains(state) {
                // 路径已经是 /bycountrycodeexact/XX 了，这里只需分页
                items.append(contentsOf: [
                    URLQueryItem(name: "limit", value: "\(limit)"),
                    URLQueryItem(name: "offset", value: "\(offset)")
                ])
            } else {
                // 普通省份走 /search 路径，需要 state 和 CN 限制
                items.append(contentsOf: [
                    URLQueryItem(name: "state", value: state),
                    URLQueryItem(name: "countrycode", value: "CN"),
                    URLQueryItem(name: "limit", value: "\(limit)"),
                    URLQueryItem(name: "offset", value: "\(offset)")
                ])
            }
            
        case .tag(let name, let limit, let offset):
            items.append(contentsOf: [
                URLQueryItem(name: "tag", value: name),
                URLQueryItem(name: "countrycode", value: "CN"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ])
            
        case .national:
            items.append(contentsOf: [
                URLQueryItem(name: "name", value: "CNR"),
                URLQueryItem(name: "countrycode", value: "CN")
            ])
        case .country(let code, let limit, let offset):
            items.append(contentsOf: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)"),
                URLQueryItem(name: "countrycode", value: code)
            ])
            
        case .search(let query, let limit, let offset):
            
            items.append(contentsOf:[
                URLQueryItem(name: "name", value: query),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ])
        }
        return items
    }
}


/**
 func fetchByState(state: String, limit: Int = 60) async throws -> [Station] {
         // 特殊处理：港澳台在 API 中通常作为 country 而不是 state
         if ["香港", "台湾", "澳门"].contains(state) {
             let code = state == "香港" ? "HK" : (state == "台湾" ? "TW" : "MO")
             return try await performRequest(path: "/stations/bycountrycodeexact/\(code)", queryItems: [
                 URLQueryItem(name: "limit", value: "\(limit)"),
                 URLQueryItem(name: "order", value: "clickcount"),
                 URLQueryItem(name: "reverse", value: "true")
             ])
         }
         
         // 普通省份请求
         return try await performRequest(
             path: "/stations/byprovince/\(state)",
             queryItems: [
                 URLQueryItem(name: "country", value: "China"),
                 URLQueryItem(name: "limit", value: "\(limit)"),
                 URLQueryItem(name: "order", value: "clickcount"),
                 URLQueryItem(name: "reverse", value: "true")
             ]
         )
     }*/
