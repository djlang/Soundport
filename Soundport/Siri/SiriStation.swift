//
//  SiriStation.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import AppIntents
import Foundation

// 这个结构体专门给 Siri 传值使用，避开 MainActor 报错
struct SiriStation: AppEntity, Identifiable, Sendable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "电台"
    static var defaultQuery = SiriStationQuery()

    let id: String // 对应 Station 的 changeuuid
    let name: String
    let state: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(state)")
    }
}


// 这里的 Query 是关键：Siri 拿到用户说的词后，会来这里问：“请给我这个名字对应的 Station 对象”
struct SiriStationQuery: EntityStringQuery {
    // 查找 ID
    func entities(for identifiers: [String]) async throws -> [SiriStation] {
        return await FavoritesManager.shared.favoriteStations
            .filter { identifiers.contains($0.changeuuid) }
            .map { SiriStation(id: $0.changeuuid, name: $0.name, state: $0.state) }
    }
    
    // 语音匹配
    func entities(matching matchingString: String) async throws -> [SiriStation] {
        return await FavoritesManager.shared.favoriteStations
            .filter { $0.name.localizedCaseInsensitiveContains(matchingString) }
            .map { SiriStation(id: $0.changeuuid, name: $0.name, state: $0.state) }
    }

    // 建议列表
    func suggestedEntities() async throws -> [SiriStation] {
        return await FavoritesManager.shared.favoriteStations
            .map { SiriStation(id: $0.changeuuid, name: $0.name, state: $0.state) }
    }
}
