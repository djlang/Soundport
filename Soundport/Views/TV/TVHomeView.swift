//
//  TVHomeView.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import SwiftUI
import AVKit
import Combine

struct TVHomeView: View {
    @StateObject var viewModel = TVViewModel()
    @State private var showingPlayer = false
    @State private var currentChannel: TVChannel?

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // 左侧分类
                List(viewModel.groups, id: \.self) { group in
                    Text(group)
                        .fontWeight(viewModel.selectedGroup == group ? .bold : .regular)
                        .foregroundColor(viewModel.selectedGroup == group ? .blue : .primary)
                        .onTapGesture { viewModel.selectedGroup = group }
                }
                .frame(width: 110)
                .listStyle(.plain)

                
                // 右侧频道
                List(viewModel.channels.filter { $0.group == viewModel.selectedGroup }) { channel in
//                    Button {
//                        currentChannel = channel
//                        showingPlayer = true
//                    } label: {
//                        HStack {
//                            // 这里可以复用你电台的 AsyncImage 组件
//                            Text(channel.name)
//                        }
//                    }
                    
                    // 在 TVHomeView 右侧列表循环中
                    NavigationLink(destination: TVVideoPlayer(channel: channel)) {
                        HStack {
                            // 你的频道 UI，比如图标和名字
                            Text(channel.name)
                        }
                    }
                }
                .listStyle(.inset)
            }
            .navigationTitle("电视直播")
            // 弹出播放器页面
            
        }
    }
}

#Preview {
    TVHomeView()
}



