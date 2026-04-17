//
//  FavoritesManager.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//

import Foundation
import Combine

class FavoritesManager: ObservableObject {
    // 保持单例，让原来的 FavoritesManager.shared 依然有效
    static let shared = FavoritesManager()
    
    @Published var favoriteStations: [Station] = [] {
        didSet {
            // 只要数组变了，就自动存盘
            saveToDisk()
        }
    }
    
    private let filename = "user_favorites_v2.json" // 换个名，防止旧数据干扰
    private let ioQueue = DispatchQueue(label: "Soundport.FavoritesManager.IO", qos: .utility)
    
    private var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }

    // 私有化 init，确保外部只能通过 .shared 访问
    private init() {
        loadFromDisk()
    }

    // --- 存盘：把数组转成 JSON 写进手机文件 ---
    private func saveToDisk() {
        let snapshot = favoriteStations
        let url = saveURL
        
        ioQueue.async {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(snapshot)
                try data.write(to: url, options: .atomic)
                print("💾 收藏已持久化，总数: \(snapshot.count)")
            } catch {
                print("❌ 存盘失败: \(error)")
            }
        }
    }

    // --- 读取：App 启动时从文件读回数组 ---
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else {
            print("ℹ️ 尚无本地收藏文件")
            return
        }
        do {
            let data = try Data(contentsOf: saveURL)
            let decoder = JSONDecoder()
            let decodedStations = try decoder.decode([Station].self, from: data)
            // 在主线程更新 UI 属性
//            DispatchQueue.main.async {
//                self.favoriteStations = decodedStations
//                print("✅ 成功从磁盘恢复 \(decodedStations.count) 个电台")
//            }
            
            self.favoriteStations = decodedStations
            print("✅ 成功从磁盘恢复 \(decodedStations.count) 个电台")
        } catch {
            print("❌ 读取收藏失败: \(error)")
        }
    }
    
    func toggleFavorite(_ station: Station) {
        if let index = favoriteStations.firstIndex(where: { $0.changeuuid == station.changeuuid }) {
            favoriteStations.remove(at: index)
        } else {
            favoriteStations.append(station)
        }
    }
    
    func isFavorite(_ station: Station) -> Bool {
        return favoriteStations.contains { $0.changeuuid == station.changeuuid }
    }
    
    // MARK: - 重排序方法
    
    /// 移动电台到新位置（用于拖拽排序）
    func moveStation(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }
        
        // 手动实现数组元素移动
        let station = favoriteStations[sourceIndex]
        favoriteStations.remove(at: sourceIndex)
        
        // 计算正确的插入位置（因为删除后索引可能变化）
        let insertIndex = destination > sourceIndex ? destination - 1 : destination
        favoriteStations.insert(station, at: insertIndex)
        
        // @Published + didSet 会自动触发存盘
    }
    
    /// 交换两个电台的位置
    func swapStations(at index1: Int, and index2: Int) {
        guard index1 != index2,
              index1 >= 0, index2 >= 0,
              index1 < favoriteStations.count,
              index2 < favoriteStations.count else { return }
        favoriteStations.swapAt(index1, index2)
        // @Published + didSet 会自动触发存盘
    }
    
    /// 上移电台
    func moveUp(at index: Int) {
        guard index > 0 else { return }
        favoriteStations.swapAt(index, index - 1)
    }
    
    /// 下移电台
    func moveDown(at index: Int) {
        guard index < favoriteStations.count - 1 else { return }
        favoriteStations.swapAt(index, index + 1)
    }
}
