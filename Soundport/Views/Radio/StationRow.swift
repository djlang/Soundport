//
//  Untitled.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/1.
//
import SwiftUI


struct StationRow: View {
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    // 1. 引入收藏单例
    @ObservedObject private var favManager = FavoritesManager.shared

    let station: Station
    
    // 判断当前电台是否正在播放
    var isPlaying: Bool {
        // 统一使用 changeuuid (或 station.id，前提是 id 已绑定 changeuuid)
        playerManager.currentStation?.changeuuid == station.changeuuid && playerManager.isPlaying
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack (alignment: .bottomTrailing) {
                // 确保模型里的 logo 字段名正确，如果是 API 数据，通常是 favicon
                
                CachedImage(url: station.logoUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    if station.name == "澳門電台 FM100.7" {
                        Image("fm1007")
                            .resizable()
                        
                    }else {
                        ZStack {
                            Color.gray.opacity(0.1)
                            Image("diantai")
                                .resizable()
                            
                        }
                    }
                    
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                
                if isPlaying {
                    LiveVisualizer(color: .pink)
                        .padding(4)

                }
            }
            
            VStack(alignment: .leading) {
                Text(station.name)
                    .font(.system(size: 15, weight: .medium))
                // 如果模型改了，frequency 可能对应的是 state 或 tags
                Text(station.frequency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 2. 使用单例的方法判断收藏状态
            let isFav = favManager.isFavorite(station)
            
            Button(action: {
                // 增加触感反馈，让真机体验更好
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    // 3. 传入整个 station 对象
                    favManager.toggleFavorite(station)
                }
            }) {
                Image(systemName: isFav ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(isFav ? .red : .gray.opacity(0.5))
                    .padding(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}
