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
                
                // 2. 覆盖的播放状态图标
                if playerManager.currentStation?.id == station.id {
                    ZStack {
                        // 半透明遮罩
                        Color.black.opacity(0.4)
                            .cornerRadius(8)
                        
                        if playerManager.isBuffering {
                            // 正在缓冲显示转圈
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else if playerManager.isPlaying {
                            // 正在播放显示波纹或暂停键
                            Image(systemName: "waveform")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        } else {
                            // 已选中但暂停显示播放键
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                    }
                    .frame(width: 50, height: 50)
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


