//
//  TVVideoPlayer.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//

import SwiftUI
import AVKit
import Combine

struct TVVideoPlayer: View {
    let channel: TVChannel
    // 使用这个特殊的 Controller 可以获得原生 UI（画中画、倍速、投屏等）
    @State private var player = AVPlayer()
    @State private var playError = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VideoPlayer(player: player)
                .onAppear {
                    setupPlayer()
                    
                }
            
            if isLoading {
                ProgressView("正在连接直播源...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            if playError {
                VStack(spacing: 15) {
                    Image(systemName: "video.slash.fill")
                        .font(.largeTitle)
                    Text("该频道暂时无法播放")
                    Text("可能由于版权限制或链接失效")
                        .font(.caption)
                    Button("重试") {
                        setupPlayer()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .foregroundColor(.white)
            }
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: channel.streamUrl) else { return }
        isLoading = true
        playError = false
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // 监听播放状态
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                if status == .failed {
                    playError = true
                    isLoading = false
                } else if status == .readyToPlay {
                    isLoading = false
                }
            }
            // 注意：这里需要存储 cancelable，实际开发建议写在 ViewModel
            
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }
}
