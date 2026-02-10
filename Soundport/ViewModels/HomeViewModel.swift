//
//  HomeViewModel.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/1.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 1. 单例定义
    static let shared = HomeViewModel()
    
    @Published var regions: [Region] = []
    @Published var selectedRegionId: String = ""
    @Published var isLoading: Bool = false
   
    @Published var searchText: String = ""
    @Published var searchResults: [Station] = []
    @Published var isSearching: Bool = false
    
    private var searchTimer: Timer?
    var isManualClick: Bool = false
    
    // MARK: - 2. 构造函数
    private init() {
        // --- 核心修复：监听 favoriteStations 而不是 IDs ---
        FavoritesManager.shared.$favoriteStations
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // 当收藏夹内容变化时，强制通知 UI 刷新（例如首页的红心状态）
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        Task {
            await loadAllData()
        }
    }
    
    // MARK: - 3. 数据处理逻辑
    
    var allStations: [Station] {
        regions.flatMap { $0.stations }
    }
    
    // 计算属性：动态获取收藏的电台分组
    var favoriteRegion: Region? {
        // --- 核心修复：直接使用完整的收藏电台数组 ---
        let favStations = FavoritesManager.shared.favoriteStations
        
        if favStations.isEmpty { return nil }
        return Region(id: "favorites_group", name: "我的收藏", stations: favStations)
    }
    
    func loadAllData() async {
        // 1. 优先尝试缓存（秒开）
        if let cachedRegions = CacheManager.loadFromCache() {
            self.regions = cachedRegions
            if self.selectedRegionId.isEmpty, let first = self.regions.first {
                self.selectedRegionId = first.id
            }
            self.isLoading = false
        } else {
            self.isLoading = true
        }
     
        do {
            // 2. 网络获取：内地、港、台并行
            async let mainland = RadioService.shared.fetchChinaDataWithDebug()
            async let hk = RadioService.shared.fetchRegionData(code: "HK", regionName: "香港")
            async let tw = RadioService.shared.fetchRegionData(code: "TW", regionName: "台湾")
            
            var allRegions = try await mainland
            let additional = try await [hk, tw]
            allRegions.append(contentsOf: additional)
            
            let sortedResult = sortRegions(allRegions)
            let finalFilteredResult = filterDuplicateStations(in: sortedResult) // 执行去重
            
            // 3. UI 线程更新
            self.regions = finalFilteredResult
            AudioPlayerManager.shared.allRegions = finalFilteredResult
            
            if self.selectedRegionId.isEmpty, let firstRegion = self.regions.first {
                self.selectedRegionId = firstRegion.id
            }
            
            CacheManager.saveToCache(sortedResult)
            print("=====>数据\(sortedResult)")
            
            print("✅ [ViewModel] 数据同步成功")
            
        } catch {
            print("❌ [ViewModel] 加载出错: \(error.localizedDescription)")
        }
        
        self.isLoading = false
    }
    
    // MARK: - 4. 搜索与排序 (逻辑保持不变)

    func performSearch() async {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
            Task {
                // 1. 在后台获取搜索文字
                let query = await self.searchText.trimmingCharacters(in: .whitespaces)
                
                guard !query.isEmpty else {
                    // 2. 修改 UI 属性必须切回主线程
                    await MainActor.run {
                        self.searchResults = []
                    }
                    return
                }
                
                // 3. 开始搜索状态
                await MainActor.run { self.isSearching = true }
                
                do {
                    let results = try await RadioService.shared.searchStations(name: query)
                    
                    // 4. 成功后切回主线程更新数据
                    await MainActor.run {
                        self.searchResults = results
                        
                        // 怀集补丁
                        if query.contains("怀集") {
                            let huaiji = Station(
                                changeuuid: "huaiji-fixed-uuid",
                                name: "怀集之声",
                                frequency: "",
                                logoUrl: "http://lhttp.qingting.fm/live/4864/64k.mp3",
                                streamUrl: "广东",
                                tags: "FM102.7",
                                state: "肇庆"
                            )
                            if !self.searchResults.contains(where: { $0.name == "怀集之声" }) {
                                self.searchResults.insert(huaiji, at: 0)
                            }
                        }
                        self.isSearching = false
                    }
                } catch {
                    print("⚠️ 搜索错误: \(error.localizedDescription)")
                    await MainActor.run {
                        self.searchResults = []
                        self.isSearching = false
                    }
                }
            }
        }
    
    }
    
    private func sortRegions(_ list: [Region]) -> [Region] {
        let topPriority = ["国家台", "广东", "香港", "台湾"]
        return list.sorted { r1, r2 in
            let index1 = topPriority.firstIndex(of: r1.name) ?? 999
            let index2 = topPriority.firstIndex(of: r2.name) ?? 999
            return index1 != index2 ? index1 < index2 : r1.name < r2.name
        }
    }
    
    
    private func filterDuplicateStations(in regions: [Region]) -> [Region] {
        return regions.map { region in
            var seenNames = Set<String>()
            let uniqueStations = region.stations.filter { station in
                // 去掉空格后对比名字
                let name = station.name.trimmingCharacters(in: .whitespaces)
                if seenNames.contains(name) {
                    return false // 名字重复了，丢掉
                } else {
                    seenNames.insert(name)
                    return true // 第一次见，保留
                }
            }
            // 返回去重后的 Region 副本
            return Region(id: region.id, name: region.name, stations: uniqueStations)
        }
    }
}

// MARK: - 5. 辅助模型 (确保与 Station 模型对应)
struct RawStation: Codable {
    let name: String
    let url_resolved: String
    let favicon: String
    let tags: String
    let state: String
    let changeuuid: String
}
