//
//  PlayRadioIntent.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import AppIntents
import Foundation

struct PlayRadioIntent: AudioStartingIntent {
    static var title: LocalizedStringResource = "播放电台"

    // 参数使用 SiriStation
    @Parameter(title: "电台")
    var target: SiriStation

    @MainActor
    func perform() async throws -> some IntentResult {
        // 通过 target.id 找到原生的 Station 并播放
        let allStaions = HomeViewModel.shared.allStations
        if let station =  allStaions.first(where: { $0.changeuuid == target.id }) {
            AudioPlayerManager.shared.play(station: station)
            return .result(dialog: "好的，正在播放\(target.name)")
        }
        return .result(dialog: "抱歉，找不到这个电台")
    }
}

