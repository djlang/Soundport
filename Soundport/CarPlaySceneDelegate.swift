//
//  CarPlaySceneDelegate.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//

import CarPlay
import Combine

@objc(CarPlaySceneDelegate)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    private var cancellables = Set<AnyCancellable>()

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // 1. 监听首页数据加载状态
        HomeViewModel.shared.$regions
            .receive(on: RunLoop.main)
            .sink { [weak self] regions in
                self?.updateUI()
            }
            .store(in: &cancellables)
            
        // 2. 监听收藏夹变化 (核心增加：手机端点收藏，车机端立刻变)
        FavoritesManager.shared.$favoriteStations
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
            
        Task {
            await HomeViewModel.shared.loadAllData()
        }
    }

    // 统一更新逻辑
    private func updateUI() {
        if HomeViewModel.shared.regions.isEmpty {
            showLoadingState()
        } else {
            refreshInterface()
        }
    }

    func showLoadingState() {
        let listTemplate = CPListTemplate(title: "声泊", sections: [
            CPListSection(items: [CPListItem(text: "正在同步电台列表...", detailText: nil)])
        ])
        interfaceController?.setRootTemplate(listTemplate, animated: false, completion: nil)
    }

    func refreshInterface() {
        // --- 核心逻辑修改 ---
        // 直接从单例获取收藏的电台数组
        let favStations = FavoritesManager.shared.favoriteStations
        let allStations = HomeViewModel.shared.allStations
        
        // 如果没有收藏，展示默认推荐（从全部电台中取前10个）
        let displayStations = favStations.isEmpty ? Array(allStations.prefix(10)) : favStations
        let title = favStations.isEmpty ? "推荐频道" : "我的收藏"

        let items = displayStations.map { station in
            // detailText 使用 station.state 或其他属性，如果没有 frequency 字段可改为 station.state
            let item = CPListItem(text: station.name ?? "未知电台", detailText: station.frequency)
            
            // 如果你有电台图标，这里可以设置图标 (可选)
            // item.setImage(UIImage(named: "radio_icon"))

            item.handler = { _, completion in
                AudioPlayerManager.shared.play(station: station)
                completion()
            }
            return item
        }

        let section = CPListSection(items: items, header: title, sectionIndexTitle: nil)
        let listTemplate = CPListTemplate(title: "声泊", sections: [section])
        
        // 使用模板刷新
        interfaceController?.setRootTemplate(listTemplate, animated: true, completion: nil)
    }
}
