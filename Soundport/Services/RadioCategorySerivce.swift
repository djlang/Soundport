//
//  RadioCategorySerivce.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/10.
//

import Foundation

class RadioCategorySerivce {
    static let shared = RadioCategorySerivce()
    private var cachedChinaStations: [Station] = [] // 缓存全量中国数据
    
    // 使用稳定的负载均衡镜像
    private let baseURL = "https://de2.api.radio-browser.info/json"
//    private let baseURL = "https://all.api.radio-browser.info/json"
    // MARK: - 1. 通用请求封装
    private func performRequest(path: String, queryItems: [URLQueryItem]) async throws -> [Station] {
        var components = URLComponents(string: "\(baseURL)\(path)")
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            print("❌ URL 构造失败")
            return []
        }
        
        var request = URLRequest(url: url)
        request.setValue("Soundport/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "RadioCategorySerivce", code: 0, userInfo: [NSLocalizedDescriptionKey: "服务器响应错误"])
        }
        
        let raw = try JSONDecoder().decode([RawStation].self, from: data)
        
        // 统计一下返回了多少个电台
        print("✅ [Network] 成功解析 \(raw.count) 个电台数据")
        return raw.map { item in
            Station(
                changeuuid: item.changeuuid,
                name: item.name,
                // 优化频率显示：优先从 tags 提取 FM/AM，否则显示地区
                frequency: extractFrequency(from: item.tags) ?? (item.state.isEmpty ? "网络广播" : item.state),
                logoUrl: item.favicon,
                streamUrl: item.url_resolved,
                tags: item.tags,
                state: item.state
            )
        }
    }
    
    // MARK: - 按需加载方法
    func fetchNationalStations() async throws -> [Station] {
        // 同时发起两个轻量级搜索：一个搜 "CNR"，一个搜 "中央"
        // TaskGroup 可以让这两个请求并行，速度极快
        return try await withThrowingTaskGroup(of: [Station].self) { group in
            let keywords = ["CNR", "中央", "中国", "CCTV"]
            for word in keywords {
                group.addTask {
                    try await self.performRequest(path: "/stations/search", queryItems: [
                        URLQueryItem(name: "name", value: word),
                        URLQueryItem(name: "countrycode", value: "CN"),
                        URLQueryItem(name: "limit", value: "20")
                    ])
                }
            }
            
            var allResults: [Station] = []
            for try await stations in group {
                allResults.append(contentsOf: stations)
            }
            // 去重（根据 UUID）
            return allResults.reduce(into: [Station]()) { res, station in
                if !res.contains(where: { $0.changeuuid == station.changeuuid }) {
                    res.append(station)
                }
            }
        }
    }
    
    /// 获取热门电台（按点击量排序）
    func fetchHotStations(limit: Int = 50) async throws -> [Station] {
        return try await performRequest(
            path: "/stations/search",
            queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "order", value: "clickcount"),
                URLQueryItem(name: "countrycode", value: "CN"),
                URLQueryItem(name: "reverse", value: "true"),
                URLQueryItem(name: "hidebroken", value: "true")
            ]
        )
    }
    
    /// 根据地区（省份）获取
    func fetchByState(state: String, limit: Int = 20) async throws -> [Station] {
        // 特殊处理：港澳台在 API 中通常作为 country 而不是 state
        if ["香港", "台湾", "澳门"].contains(state) {
            let code = state == "香港" ? "HK" : (state == "台湾" ? "TW" : "MO")
            return try await performRequest(path: "/stations/bycountrycodeexact/\(code)", queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "reverse", value: "true")
            ])
        }
        else {
            // 普通省份请求
            return try await performRequest(
                path: "/stations/bystate/\(state)",
                queryItems: [
                    URLQueryItem(name: "countrycode", value: "CN"),
                    URLQueryItem(name: "limit", value: "\(limit)"),
                    URLQueryItem(name: "reverse", value: "true")
                ]
            )
        }
        
    }
    
    
    
    /// 根据标签获取（音乐、交通、新闻、经济等）
    func fetchByTag(tag: String, limit: Int = 20) async throws -> [Station] {
        return try await performRequest(
            path: "/stations/bytag/\(tag)",
            queryItems: [
                URLQueryItem(name: "countrycode", value: "CN"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "order", value: "clickcount"),
                URLQueryItem(name: "reverse", value: "true")
            ]
        )
    }
    
    /// 搜索电台
    func searchStations(name: String, limit: Int = 20) async throws -> [Station] {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await performRequest(
            path: "/stations/byname/\(cleanedName)",
            queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "hidebroken", value: "true")
            ]
        )
    }
    
    // MARK: - 3. 辅助逻辑
    
    private func extractFrequency(from tags: String) -> String? {
        let components = tags.lowercased().components(separatedBy: ",")
        // 寻找形如 "fm 102.7" 或 "97.5" 的标签
        for tag in components {
            let trimmed = tag.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("fm") || trimmed.contains("am") {
                return trimmed.uppercased()
            }
        }
        return nil
    }
}
