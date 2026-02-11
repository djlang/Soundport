//
//  RadioViewModel.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/10.
//

import Foundation
import Combine
import SwiftUI

// 定义左侧侧边栏分类
enum RadioCategory: String, CaseIterable, Identifiable {
    case favorites = "收藏"
    case hot = "热门"
    case region = "地区"      // 动态显示：如“广东”
    case national = "国家台"
    case traffic = "交通台"
    case music = "音乐台"
    case news = "新闻台"
    case sports = "体育台"
    case business = "经济"
    case culture = "文化"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .favorites: return "heart.fill"
        case .hot: return "flame.fill"
        case .region: return "mappin.and.ellipse"
        case .national: return "antenna.radiowaves.left.and.right"
        case .traffic: return "car.fill"
        case .music: return "music.note"
        case .news: return "newspaper.fill"
        case .sports: return "figure.run"
        case .business: return "dollarsign"
        case .culture: return "lightbulb.fill"
        }
    }
}

@MainActor
class RadioViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    static let shared = RadioViewModel()
    
    
    
    // MARK: - 状态属性
    @Published var selectedCategory: RadioCategory = .hot
    @Published var selectedProvince: String = "广东" // 地区分类的具体省份
    @Published var stations: [Station] = []        // 当前右侧显示的电台列表
    @Published var isLoading: Bool = false
    
    // 搜索相关
    @Published var searchText: String = ""
    @Published var searchResults: [Station] = []
    @Published var isSearching: Bool = false
    @Published var showProvincePicker: Bool = false // 控制省份点选弹窗
    
    private var searchTimer: Timer?
    
    private let service = RadioCategorySerivce.shared
    
    // MARK: - 初始化
    private init() {
        // 监听收藏夹变化，实时刷新右侧列表
//        FavoritesManager.shared.$favoriteStations
//            .receive(on: RunLoop.main)
//            .sink { [weak self] _ in
//                if self?.selectedCategory == .favorites {
//                    self?.loadCurrentCategoryData()
//                }
//            }
//            .store(in: &cancellables)
            
        Task {
            await selectCategory(.favorites) // 默认进入
        }
    }
    
    // MARK: - 核心业务逻辑
    
    /// 切换左侧分类
    func selectCategory(_ category: RadioCategory) async {
        self.selectedCategory = category
        await loadCurrentCategoryData()
    }
    
    /// 切换具体省份（地区点选后调用）
    func changeProvince(to province: String) async {
        self.selectedProvince = province
        self.selectedCategory = .region
        await loadCurrentCategoryData()
    }
    
    /// 根据当前分类加载右侧数据
    func loadCurrentCategoryData() async {
        self.isLoading = true
        self.stations = [] // 清空当前列表
        
        do {
            switch selectedCategory {
            case .favorites:
                self.stations = FavoritesManager.shared.favoriteStations
                
            case .hot:
                // 假设 RadioService 有获取热门的方法，或者直接按点击量搜
                self.stations = try await service.searchStations(name: " ", limit: 20)
                
            case .region:
                // 使用 RegionMapper 将中文转为 API 参数 (如 "广东" -> "Guangdong")
                let apiParam = RegionMapper.toApiParameter(selectedProvince)
                // 这里假设你 RadioService 增加了 fetchByState 方法
                self.stations = try await service.fetchByState(state: apiParam, limit: 20)
                
            case .national:
                self.stations = try await service.fetchNationalStations()
                
            case .traffic, .music, .news, .sports, .business, .culture:
                // 按标签搜索：如 tag="traffic"
                let tagMap: [RadioCategory: String] = [.traffic: "traffic", .music: "music", .news: "news", .sports: "sports", .business: "business", .culture: "culture"]
                self.stations = try await service.fetchByTag(tag: tagMap[selectedCategory] ?? "")
            
            }
            
            // 统一去重处理
            self.stations = filterDuplicates(self.stations)
            
            // 同步给播放器（用于切歌列表）
            AudioPlayerManager.shared.allRegions = [Region(id: "current", name: selectedCategory.rawValue, stations: self.stations)]
            
        } catch {
            print("❌ 加载分类数据失败: \(error)")
        }
        self.isLoading = false
    }
    
    // MARK: - 辅助方法
    
    private func filterDuplicates(_ list: [Station]) -> [Station] {
        var seenNames = Set<String>()
        return list.filter { station in
            let name = station.name.trimmingCharacters(in: .whitespaces)
            return seenNames.insert(name).inserted
        }
    }

    // 搜索逻辑保持不变，但结果可以映射给 searchResults
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
                    let results = try await self.service.searchStations(name: query)
                    
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
}
