//
//  Station.swift
//  Soundport
//
//  Created by dengjinlang on 2026/1/31.
//

import Foundation

// 电台模型
struct Station: Identifiable, Hashable,Codable {
    let id = UUID()
    let name: String
    let frequency: String
    let logoUrl: String // 暂时用系统图标代替
    let streamUrl: String
    let tags: String
}

// 地区模型，包含该地区下的电台列表
struct Region: Identifiable, Hashable, Codable {
    let id: String // 用于 ScrollViewReader 的锚点 ID
    let name: String
    let stations: [Station]
}
