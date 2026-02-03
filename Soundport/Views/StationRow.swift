//
//  Untitled.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/1.
//
import SwiftUI


struct StationRow: View {
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @ObservedObject private var favManager = FavoritesManager.shared
    
    let station: Station
    // 判断当前电台是否正在播放
    var isPlaying: Bool {
        playerManager.currentStation?.id == station.id && playerManager.isPlaying
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 在 StationRow 或 miniPlayer
            ZStack {
                CachedImage(url: station.logoUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    // 诗意的占位图：半透明背景加系统图标
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "radio")
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                //logo旋转
//                .rotationEffect(.degrees(isPlaying ? 360 : 0))
//                .animation(isPlaying ? .linear(duration: 10).repeatForever(autoreverses: false) : .default, value: isPlaying)
                // 2. 覆盖的播放状态图标
                if isPlaying {
                    LiveVisualizer(color: .pink) // 在 Logo 上用白色比较显眼
                }
            }
            
            VStack(alignment: .leading) {
                Text(station.name).font(.system(size: 15, weight: .medium))
                Text(station.frequency).font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            let isFav = favManager.favoriteIDs.contains(station.id)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    favManager.toggleFavorite(stationID: station.id)
                }
            }) {
                Image(systemName: isFav ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(isFav ? .red : .gray.opacity(0.5))
                    .padding(10) // 增大点击热区
            }
            .buttonStyle(PlainButtonStyle())
        }
        .contentShape(Rectangle()) // 确保整行（除了按钮）都可点击播放
        .padding(.vertical, 4)
    }
}


