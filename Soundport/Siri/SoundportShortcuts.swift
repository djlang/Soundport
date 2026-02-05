//
//  SoundportShortcuts.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import AppIntents

struct SoundportShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayRadioIntent(),
            phrases: [
                "用 \(.applicationName) 播放 \(\.$stationName)",
                "在 \(.applicationName) 开启 \(\.$stationName)",
                "想听 \(.applicationName) 里的 \(\.$stationName)",
                "用 声泊电台 播放 \(\.$stationName)",
            ],
            shortTitle: "播放电台",
            systemImageName: "radio"
        )
    }
}
