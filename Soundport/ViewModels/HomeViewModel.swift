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
    
    @Published var regions: [Region] = []
    @Published var selectedRegionId: String = ""
    @Published var isLoading: Bool = false
   
    @Published var searchText: String = ""
    @Published var searchResults: [Station] = []
    @Published var isSearching: Bool = false
    
    private var searchTimer: Timer? // 用于防抖，避免频繁请求
    
    // 标记是否由用户主动点击左侧菜单，防止滚动时的反向联动干扰
    var isManualClick: Bool = false
    
    init() {
        // 监听 FavoritesManager 的变化，一旦变化就通知 ViewModel 刷新
        FavoritesManager.shared.$favoriteIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // 计算属性：动态获取收藏的电台分组
    var favoriteRegion: Region? {
        let favIDs = FavoritesManager.shared.favoriteIDs
        if favIDs.isEmpty { return nil }
        
        let allStations = regions.flatMap { $0.stations }
        let favStations = allStations.filter { favIDs.contains($0.id) }
        
        if favStations.isEmpty { return nil }
        return Region(id: "favorites_group", name: "我的收藏", stations: favStations)
    }
    
    func loadAllData() async {
        // 避免重复加载
        guard regions.isEmpty else { return }
        
        isLoading = true
        print("🚀 [ViewModel] 开始全量数据加载与智能分组...")
        
        do {
            // 1. 获取内地全量数据（包含 Service 内部的分组和中英映射）
            var allRegions = try await RadioService.shared.fetchChinaDataWithDebug()
            
            // 2. 并行获取港台数据（保持这两大分类的独立性）
            async let hk = RadioService.shared.fetchRegionData(code: "HK", regionName: "香港")
            async let tw = RadioService.shared.fetchRegionData(code: "TW", regionName: "台湾")
            
            let additionalRegions = try await [hk, tw]
            allRegions.append(contentsOf: additionalRegions)
            
            // 3. 排序策略：国家台/其他排在前面，或者按字母排
            // 这里我们把“国家台”和“广东”等热门置顶，其他的按字母排
            self.regions = sortRegions(allRegions)
            
            AudioPlayerManager.shared.allRegions = sortRegions(allRegions)
            
            // 4. 设置默认选中项
            if let firstRegion = self.regions.first {
                self.selectedRegionId = firstRegion.id
            }
            
            print("✅ [ViewModel] 数据装载完成，共 \(self.regions.count) 个分组")
            
        } catch {
            print("❌ [ViewModel] 加载流程出错: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // 执行搜索
    func performSearch() async {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
            // 这里的闭包在非隔离上下文中运行
            Task {
                let query = await self.searchText.trimmingCharacters(in: .whitespaces)
                guard !query.isEmpty else {
                    // 错误：不能直接 self.searchResults = []
                    await MainActor.run {
                        self.searchResults = []
                    }
                    return
                }
                
                // 异步任务开始
                await MainActor.run { self.isSearching = true }
                
                do {
                    let results = try await RadioService.shared.searchStations(name: query)
                    
                    // 成功：切回主线程更新 UI
                    await MainActor.run {
                        self.searchResults = results
                        self.isSearching = false
                    }
                } catch {
                    print("⚠️ 搜索捕获到错误: \(error.localizedDescription)")
                    
                    // 失败：切回主线程重置状态
                    await MainActor.run {
                        self.searchResults = []
                        self.isSearching = false
                    }
                }
                if query.contains("怀集") {
                    let huaiji = Station(name: "怀集之声", frequency: "FM", logoUrl: "", streamUrl: "你的地址", tags: "广东")
                    await MainActor.run {
                        self.searchResults.insert(huaiji, at: 0)
                    }
                }
            }
            
           
        }
        
        
    }
    
    // 辅助排序方法：让列表更符合用户习惯
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
// 解析专用的原始模型
struct RawState: Codable { let name: String }
struct RawStation: Codable {
    let name: String
    let url_resolved: String
    let favicon: String
    let tags: String
    let state: String
}
