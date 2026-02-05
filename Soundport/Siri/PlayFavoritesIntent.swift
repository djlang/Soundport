//
//  PlayFavoritesIntent.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//
import AppIntents
import Foundation

struct PlayFavoritesIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "播放收藏电台"
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let favorites = FavoritesManager.shared.favoriteStations
        guard let first = favorites.first else {
            return .result(dialog: "你的收藏夹还是空的呢")
        }
        
        AudioPlayerManager.shared.play(station: first)
        return .result(dialog: "正在播放收藏夹里的\(first.name)")
    }
}
