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
        
        // 1. 监听数据加载状态
        HomeViewModel.shared.$regions
            .receive(on: RunLoop.main)
            .sink { [weak self] regions in
                if !regions.isEmpty {
                    self?.refreshInterface()
                } else {
                    self?.showLoadingState()
                }
            }
            .store(in: &cancellables)
            
        // 2. 确保启动了加载
        Task {
            await HomeViewModel.shared.loadAllData()
        }
    }

    func showLoadingState() {
        let listTemplate = CPListTemplate(title: "枕流", sections: [
            CPListSection(items: [CPListItem(text: "正在同步电台列表...", detailText: nil)])
        ])
        interfaceController?.setRootTemplate(listTemplate, animated: false, completion: nil)
    }

    func refreshInterface() {
        let favIDs = FavoritesManager.shared.favoriteIDs
        let allStations = HomeViewModel.shared.allStations
        
        // 过滤收藏
        let favStations = allStations.filter { favIDs.contains($0.id) }
        
        // 如果没有收藏，展示默认推荐（避免列表完全为空）
        let displayStations = favStations.isEmpty ? Array(allStations.prefix(10)) : favStations
        let title = favStations.isEmpty ? "推荐频道" : "我的收藏"

        let items = displayStations.map { station in
            let item = CPListItem(text: station.name, detailText: station.frequency)
            item.handler = { _, completion in
                AudioPlayerManager.shared.play(station: station)
                completion()
            }
            return item
        }

        let section = CPListSection(items: items, header: title, sectionIndexTitle: nil)
        let listTemplate = CPListTemplate(title: "枕流", sections: [section])
        
        interfaceController?.setRootTemplate(listTemplate, animated: true, completion: nil)
    }
}
