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
                "用 \(.applicationName) 播放 \(\.$target)",
                "在 \(.applicationName) 开启 \(\.$target)"
            ],
            shortTitle: "播放广播",
            systemImageName: "radio"
        )
    }
}
