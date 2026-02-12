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
    static let shared = RadioViewModel()
    
    @Published var selectedCategory: RadioCategory = .favorites
    @Published var selectedProvince: String = "广东"
    @Published var stations: [Station] = []
    @Published var isLoading: Bool = false
    @Published var isFetchingMore: Bool = false
    @Published var canLoadMore: Bool = true
    @Published var showProvincePicker: Bool = false
    
    @Published var loadError: Bool = false // 记录是否加载失败
    
    private var currentPage = 0
    private let pageSize = 10
    private let service = RadioCategorySerivce.shared

    private init() {
        Task { await selectCategory(.hot) }
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
        await selectCategory(.region)
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
            case .national:
                task = .national
            case .favorites:
                self.stations = FavoritesManager.shared.favoriteStations
                self.isLoading = false
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
        case .business: return "business"
        case .culture: return "culture"
        default: return ""
        }
    }

    private func filterDuplicates(_ list: [Station]) -> [Station] {
        var seenIDs = Set<String>()
        // 结合 stations 已有的 ID 和新获取的进行去重
        let existingIDs = Set(stations.map { $0.changeuuid })
        seenIDs.formUnion(existingIDs)
        
        return list.filter { seenIDs.insert($0.changeuuid).inserted }
    }
}
