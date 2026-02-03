//
//  RadioService.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/1.
//

import Foundation

/// 最终版：支持调试打印、自动分组与容错处理的电台服务
class RadioService {
    static let shared = RadioService()
    
    // 使用分布式负载均衡域名，提高国内访问稳定性
    private let baseURL = "https://all.api.radio-browser.info/json"
    
    private let provinceMapping = [
        "Guangdong": "广东", "Beijing": "北京", "Shanghai": "上海",
        "Zhejiang": "浙江", "Jiangsu": "江苏", "Fujian": "福建",
        "Sichuan": "四川", "Hubei": "湖北", "Shandong": "山东"
    ]

    func fetchChinaDataWithDebug() async throws -> [Region] {
            print("🚩 [DEBUG] RadioService 方法已被激活！")
            
            let urlString = "\(baseURL)/stations/bycountrycodeexact/CN?limit=500&order=clickcount&reverse=true"
            guard let url = URL(string: urlString) else {
                print("❌ [DEBUG] URL 构造失败"); return []
            }
            
            print("🌐 [DEBUG] 正在请求: \(url.absoluteString)")
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let resp = response as? HTTPURLResponse {
                print("📩 [DEBUG] 服务器状态码: \(resp.statusCode)")
            }

            // 核心：如果没看到广东，我们直接打印所有 state 字段，看看它们到底叫什么
            let raw = try JSONDecoder().decode([RawStation].self, from: data)
            let allStates = Set(raw.compactMap { $0.state })
            print("📊 [DEBUG] API 返回的所有省份字段列表: \(allStates)")
            
            var groupDict: [String: [Station]] = [:]
            
            for item in raw {
                // 改进匹配逻辑：只要名字里带广东，或者 state 字段是 Guangdong 或 广东
                let name = item.name.lowercased()
                let state = (item.state).lowercased()
                
                var category = "其他"
                if name.contains("gd") || name.contains("guangdong") || name.contains("广东") || state.contains("guangdong") || state.contains("广东") {
                    category = "广东"
                } else if name.contains("cnr") || name.contains("中央") || name.contains("北京") {
                    category = "国家台"
                } else if !state.isEmpty {
                    category = item.state // 使用原始省份名
                }
                
                let station = Station(
                    name: item.name,
                    frequency: item.tags.split(separator: ",").first.map(String.init) ?? "网络广播",
                    logoUrl: item.favicon,
                    streamUrl: item.url_resolved,
                    tags: item.tags
                )
                groupDict[category, default: []].append(station)
            }
            
            return groupDict.map { Region(id: $0.key, name: $0.key, stations: $0.value) }
                .sorted { $0.name < $1.name }
        }
    
    /// 专门获取香港/台湾数据的简化方法
    func fetchRegionData(code: String, regionName: String) async throws -> Region {
        let urlString = "\(baseURL)/stations/bycountrycodeexact/\(code)?limit=50"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        struct RawStation: Codable {
            let name: String
            let url_resolved: String
            let favicon: String
            let tags: String
        }
        
        let raw = try JSONDecoder().decode([RawStation].self, from: data)
        let stations = raw.map {
            Station(name: $0.name, frequency: regionName, logoUrl: $0.favicon, streamUrl: $0.url_resolved, tags: $0.tags)
        }
        
        return Region(id: code, name: regionName, stations: stations)
    }
    
    // 在 RadioService 类中添加
    func searchStations(name: String) async throws -> [Station] {
        // 1. 使用 de1 这个通常最稳定的镜像
        // 2. 增加 limit=20 减少数据量，提高加载速度
        let urlString = "https://de1.api.radio-browser.info/json/stations/byname/\(name)?countrycode=CN&limit=20"
        
        // 清理搜索词中的特殊空格或字符（你报错的 URL 里似乎含有一个非标准空格 %E2%80%86）
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let encodedName = cleanedName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://de1.api.radio-browser.info/json/stations/byname/\(encodedName)?countrycode=CN&limit=20") else {
            return []
        }
        
        // 配置请求，明确告诉服务器我们接受 JSON
        var request = URLRequest(url: url)
        request.setValue("声泊 Radio/1.0", forHTTPHeaderField: "User-Agent") // 规范：添加 User-Agent
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 检查是否是 HTTPS 错误
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "RadioService", code: 0, userInfo: [NSLocalizedDescriptionKey: "服务器响应错误"])
        }
        
        let rawStations = try JSONDecoder().decode([RawStation].self, from: data)
        
        return rawStations.map { raw in
            Station(
                name: raw.name,
                frequency: raw.tags.components(separatedBy: ",").first ?? "Internet",
                logoUrl: raw.favicon,
                streamUrl: raw.url_resolved,
                tags: raw.tags
            )
        }
    }
}
