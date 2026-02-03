//
//  HomeViewModel.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/1.
//


import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 1. 单例定义
    // 使用单例模式确保 CarPlay 和手机端共享同一份内存数据
    static let shared = HomeViewModel()
    
    @Published var regions: [Region] = []
    @Published var selectedRegionId: String = ""
    @Published var isLoading: Bool = false
   
    @Published var searchText: String = ""
    @Published var searchResults: [Station] = []
    @Published var isSearching: Bool = false
    
    private var searchTimer: Timer? // 用于防抖
    
    // 标记是否由用户主动点击左侧菜单
    var isManualClick: Bool = false
    
    // MARK: - 2. 构造函数
    // 设为 private 确保外部只能通过 .shared 访问
    private init() {
        // 监听 FavoritesManager 的变化，一旦变化就通知 ViewModel 刷新
        FavoritesManager.shared.$favoriteIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        // 可以在初始化时自动加载一次数据
        Task {
            await loadAllData()
        }
    }
    
    // MARK: - 3. 数据处理逻辑
    
    // 提供给 CarPlay 使用的平铺电台列表
    var allStations: [Station] {
        regions.flatMap { $0.stations }
    }
    
    // 计算属性：动态获取收藏的电台分组
    var favoriteRegion: Region? {
        let favIDs = FavoritesManager.shared.favoriteIDs
        if favIDs.isEmpty { return nil }
        
        // 从当前已加载的所有分组中寻找匹配收藏 ID 的电台
        let favStations = allStations.filter { favIDs.contains($0.id) }
        
        if favStations.isEmpty { return nil }
        return Region(id: "favorites_group", name: "我的收藏", stations: favStations)
    }
    
    func loadAllData() async {
        // 1. 尝试先从缓存加载（秒开界面）
        if let cachedRegions = CacheManager.loadFromCache() {
            self.regions = cachedRegions
            if let first = self.regions.first {
                self.selectedRegionId = first.id
            }
            // 如果缓存有数据，可以提前关闭 loading，提升用户感知的“快”
            self.isLoading = false
        } else {
            self.isLoading = true
        }
     
        
        do {
            // 1. 获取内地全量数据
            var allRegions = try await RadioService.shared.fetchChinaDataWithDebug()
            
            // 2. 并行获取港台数据
            async let hk = RadioService.shared.fetchRegionData(code: "HK", regionName: "香港")
            async let tw = RadioService.shared.fetchRegionData(code: "TW", regionName: "台湾")
            
            let additionalRegions = try await [hk, tw]
            allRegions.append(contentsOf: additionalRegions)
            
            // 3. 排序策略
            let sortedResult = sortRegions(allRegions)
            
            await MainActor.run {
                self.regions = sortedResult
                // 同步给播放管理器的全量列表（如果需要）
                AudioPlayerManager.shared.allRegions = sortedResult
                // 4. 设置默认选中项
                if let firstRegion = self.regions.first {
                    self.selectedRegionId = firstRegion.id
                }
                self.isLoading = false
                // 写入本地，供下次启动使用
                CacheManager.saveToCache(sortedResult)
            }
            
            
            
            print("✅ [ViewModel] 数据装载完成，共 \(self.regions.count) 个分组")
            
        } catch {
            print("❌ [ViewModel] 加载流程出错: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - 4. 搜索逻辑
    
    func performSearch() async {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
            Task {
                let query = await self.searchText.trimmingCharacters(in: .whitespaces)
                guard !query.isEmpty else {
                    await MainActor.run {
                        self.searchResults = []
                    }
                    return
                }
                
                await MainActor.run { self.isSearching = true }
                
                do {
                    let results = try await RadioService.shared.searchStations(name: query)
                    
                    await MainActor.run {
                        self.searchResults = results
                        
                        // 怀集补丁逻辑
                        if query.contains("怀集") {
                            let huaiji = Station(name: "怀集之声", frequency: "FM102.7", logoUrl: "", streamUrl: "http://lhttp.qingting.fm/live/4864/64k.mp3", tags: "广东")
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
            
            if index1 != index2 {
                return index1 < index2
            } else {
                return r1.name < r2.name
            }
        }
    }
}

// MARK: - 模型定义
struct RawState: Codable { let name: String }
struct RawStation: Codable {
    let name: String
    let url_resolved: String
    let favicon: String
    let tags: String
    let state: String
}
