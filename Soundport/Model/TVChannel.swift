//
//  TVChannel.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import Foundation

struct TVChannel: Identifiable, Codable {
    let id = UUID()
    let name: String
    let group: String // 分类：中国内地、港澳台等
    let logo: String
    let streamUrl: String // IPTV 的播放地址 (m3u8)
}
