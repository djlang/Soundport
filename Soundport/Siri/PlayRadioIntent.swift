//
//  PlayRadioIntent.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import AppIntents
import Foundation

struct PlayRadioIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "播放电台"
    static var description = IntentDescription("通过电台名称搜索并播放。")

    // Siri 提示语：用户可以说“用 Soundport 播放怀集之声”
    static var parameterSummary: some ParameterSummary {
        Summary("播放 \(\.$stationName)")
    }

    // 定义参数：电台名称
    @Parameter(title: "电台名称", default: "音乐电台")
    var stationName: String

    // 核心执行逻辑
    @MainActor
    func perform() async throws -> some IntentResult {
        // 1. 在 ViewModel 或全量数据中查找最匹配的电台
        let allStations = HomeViewModel.shared.allStations
        
        // 模糊匹配：寻找名字里包含用户说的话的电台
        if let targetStation = allStations.first(where: { $0.name.contains(stationName) }) {
            // 2. 调用播放器开始播放
            AudioPlayerManager.shared.play(station: targetStation)
            
            // 3. 返回成功结果，Siri 会回答你
            return .result(dialog: "好的，正在为你播放\(targetStation.name)")
        } else {
            return .result(dialog: "抱歉，没找到名字叫\(stationName)的电台")
        }
    }
}
