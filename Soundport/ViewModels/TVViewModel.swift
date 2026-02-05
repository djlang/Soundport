//
//  TVViewModel.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import Foundation
import Combine

class TVViewModel: ObservableObject {
    @Published var channels: [TVChannel] = []
    @Published var groups: [String] = []
    @Published var selectedGroup: String = ""
    @Published var isLoading = false

    // 这里使用一个常见的 GitHub 开源 M3U 链接（IPv6/IPv4 混合）
    //https://live.fanmingming.com/tv/m3u/ipv6.m3u
    //https://iptv-org.github.io/iptv/countries/cn.m3u
    //https://raw.githubusercontent.com/YueChan/Live/main/IPTV.m3u
    //https://raw.githubusercontent.com/hujingguang/ChinaIPTV/main/grouped.m3u8
    
    //https://raw.githubusercontent.com/fanmingming/live/main/tv/m3u/ipv6.m3u
    
    private let m3uURL = "https://live.fanmingming.com/tv/m3u/ipv6.m3u"

    init() {
        fetchTVChannels()
    }

    func fetchTVChannels() {
        guard let url = URL(string: m3uURL) else { return }
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            let parsedChannels = M3UParser.parse(text)
            
            DispatchQueue.main.async {
                self.channels = parsedChannels
                // 提取所有分组并去重
                let allGroups = Array(Set(parsedChannels.map { $0.group })).sorted()
                // 过滤掉一些可能为空或者没用的分组
                self.groups = allGroups.filter { !$0.isEmpty }
                self.selectedGroup = self.groups.first ?? ""
                self.isLoading = false
            }
        }.resume()
    }
}
