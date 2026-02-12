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
    case country = "其他国家"
    
    
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
        case .country: return "globe.americas.fill"
        }
    }
}



@MainActor
class RadioViewModel: ObservableObject {
    static let shared = RadioViewModel()
    
    @Published var selectedCategory: RadioCategory = .favorites
    @Published var selectedProvince: String = "广东"
    @Published var selectedCountry: String = "其他国家"
    @Published var stations: [Station] = []
    @Published var isLoading: Bool = false
    @Published var isFetchingMore: Bool = false
    @Published var canLoadMore: Bool = true
    @Published var showProvincePicker: Bool = false
    @Published var showCountryPicker: Bool = false
    
    
    @Published var loadError: Bool = false // 记录是否加载失败
    
    // 定义常量 Key 避免拼写错误
    private let lastProvinceKey = "AppLastSelectedProvince"
    
    private var currentPage = 0
    private let pageSize = 10
    private let service = RadioCategorySerivce.shared

    private init() {
        self.selectedCategory = .favorites
        self.selectedProvince = UserDefaults.standard.string(forKey: lastProvinceKey) ?? "广东"
        // 2. 恢复播放器状态（只显示不播放）
        AudioPlayerManager.shared.restoreLastStation()
        Task { await loadData()}
    }

    /// 切换大类
    func selectCategory(_ category: RadioCategory) async {
        self.selectedCategory = category
        self.currentPage = 0
        self.canLoadMore = true
        await loadData(isNextPage: false)
    }

    /// 切换省份
    func changeProvince(to province: String) async {
        self.selectedProvince = province
        // 💾 保存：每当切换省份，立刻存入本地
        UserDefaults.standard.set(province, forKey: lastProvinceKey)
        
        await selectCategory(.region)
    }
    
    // 切换国家
    func changeCountry(to country: String) async {
        self.selectedCountry = country
        await selectCategory(.country)
    }
    
    /// 核心加载方法
    func loadData(isNextPage: Bool = false) async {
        guard !isLoading && !isFetchingMore else { return }
        
        if isNextPage {
            guard canLoadMore else { return }
            isFetchingMore = true
        } else {
            isLoading = true
            stations = []
            currentPage = 0
        }

        let offset = currentPage * pageSize
        
        do {
            let task: RadioTask
            switch selectedCategory {
         
            case .hot:
                task = .hot(limit: pageSize, offset: offset)
            case .region:
                let apiParam = RegionMapper.toApiParameter(selectedProvince)
                task = .region(state: apiParam, limit: pageSize, offset: offset)
                
            case .country:
                let apiParam = RegionMapper.toApiParameterForCountry(selectedCountry)
                task = .country(code: apiParam, limit: pageSize, offset: offset)
            case .national:
                task = .national(limit: pageSize,offset: offset)
            case .favorites:
                let favs = FavoritesManager.shared.favoriteStations
                self.stations = favs
                self.canLoadMore = false
                self.loadError = false
                self.isLoading = false
                self.isFetchingMore = false
                // 同步给播放器（用于切台列表）
                AudioPlayerManager.shared.allRegions = [
                    Region(id: "fav", name: "我的收藏", stations: favs)
                ]
                return
    
            default:
                // 对应音乐、交通、新闻等标签分类
                let tag = categoryToTag(selectedCategory)
                task = .tag(name: tag, limit: pageSize, offset: offset)
            }

            let newStations = try await service.executeTask(task)
            let filtered = filterDuplicates(newStations)

            if isNextPage {
                self.stations.append(contentsOf: filtered)
            } else {
                self.stations = filtered
            }

            // 更新状态
            self.canLoadMore = newStations.count >= pageSize
            self.currentPage += 1
            
        } catch {
            print("❌ Error: \(error)")
            self.loadError = true // 标记失败
        }

        self.isLoading = false
        self.isFetchingMore = false
    }

    private func categoryToTag(_ category: RadioCategory) -> String {
        switch category {
        case .traffic: return "traffic"
        case .music: return "music"
        case .news: return "news"
        case .sports: return "sports"
        case .business: return "economics"    //business"
        case .culture: return "culture"
        default: return ""
        }
    }
    
    @Published var searchText: String = ""
    @Published var searchResults: [Station] = []
    @Published var isSearching: Bool = false
    
    func performSearchRadio(_ isNextPage: Bool = false) async {
        
        if isNextPage {
            guard canLoadMore else { return }
            isFetchingMore = true
        } else {
            isLoading = true
            searchResults = []
            currentPage = 0
        }
        
        
        
        let offset = currentPage * pageSize
        let query = self.searchText.trimmingCharacters(in: .whitespaces)
        guard  !query.isEmpty else {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        await MainActor.run { self.isSearching = true }
        do {
            let task: RadioTask
            task = .search(query: query, limit: pageSize, offset: offset)
            self.isSearching = false
            let newStations = try await service.executeTask(task)
            let filtered = filterDuplicates(newStations)
            
            
            if isNextPage {
                self.searchResults.append(contentsOf: filtered)
            } else {
                self.searchResults = filtered
            }
            
            // 更新状态
            self.canLoadMore = newStations.count >= pageSize
            self.currentPage += 1
        }catch {
            print("❌ Error: \(error)")
            self.loadError = true // 标记失败
            self.searchResults = []
            self.isSearching = false
        }
        
        self.isLoading = false
        self.isFetchingMore = false
    
    }
    
    

    private func filterDuplicates(_ list: [Station]) -> [Station] {
        // 1. 记录集合
        var seenIDs = Set<String>()
        var seenNames = Set<String>()
        
        // 2. 将现有电台信息存入集合
        for station in stations {
            seenIDs.insert(station.changeuuid)
            seenNames.insert(station.name.lowercased().trimmingCharacters(in: .whitespaces))
        }
        
        // 3. 【关键步骤】对新获取的列表进行预排序
        // 将有 logoUrl 的排在前面，没有的排在后面
        let sortedList = list.sorted { (a, b) -> Bool in
            let aHasLogo = !(a.logoUrl.isEmpty)
            let bHasLogo = !(b.logoUrl.isEmpty)
            if aHasLogo != bHasLogo {
                return aHasLogo // 有 Logo 的优先
            }
            return false // 都有或都没有则保持原序（原序通常按点击量排，也很重要）
        }
        
        // 4. 执行去重
        return sortedList.filter { station in
            let normalizedName = station.name.lowercased().trimmingCharacters(in: .whitespaces)
            
            // 尝试插入 UUID 和 名字
            let isNewID = seenIDs.insert(station.changeuuid).inserted
            let isNewName = seenNames.insert(normalizedName).inserted
            
            // 如果是全新的电台（ID和名字都没见过），则保留
            // 由于 sortedList 里有 Logo 的在前，所以同名电台第一个被遇到的肯定是有 Logo 的
            return isNewID && isNewName
        }
    }
}


