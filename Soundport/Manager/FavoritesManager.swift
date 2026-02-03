//
//  FavoritesManager.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//

import Foundation
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    // 1. 将类型改为 Set<UUID>
    @Published var favoriteIDs: Set<UUID> = [] {
        didSet { saveToDisk() }
    }
    
    private let saveKey = "user_favorite_stations_uuids"
    
    private init() { loadFromDisk() }
    
    func toggleFavorite(stationID: UUID) { // 参数改为 UUID
        if favoriteIDs.contains(stationID) {
            favoriteIDs.remove(stationID)
        } else {
            favoriteIDs.insert(stationID)
        }
    }
    
    private func saveToDisk() {
        // 2. 保存时转为 String 数组（UserDefaults 不支持直接存 UUID 集合）
        let array = favoriteIDs.map { $0.uuidString }
        UserDefaults.standard.set(array, forKey: saveKey)
    }
    
    private func loadFromDisk() {
        // 3. 读取时转回 UUID
        if let array = UserDefaults.standard.stringArray(forKey: saveKey) {
            favoriteIDs = Set(array.compactMap { UUID(uuidString: $0) })
        }
    }
}
