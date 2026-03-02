//
//  RadioMiniPlayerView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI

struct RadioMiniPlayerView: View {
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @StateObject private var favManager = FavoritesManager.shared
    @ObservedObject private var sleepManager = SleepTimerManager.shared

    @StateObject private var shazamManager = ShazamManager()
    @State private var angle: Double = 0

    let onSleepTimerTap: () -> Void

    var body: some View {
        Group {
            if let station = playerManager.currentStation {
                VStack(spacing: 0) {
                    Divider()
                    VStack {
                        HStack(spacing: 15) {
                            CachedImage(url: station.logoUrl) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image("shouyinji")
                                    .resizable()
                            }
                            .frame(width: 38, height: 38)
                            .cornerRadius(19)
                            .rotationEffect(.degrees(angle))
                            .onAppear { startRotate() }
                            .id("logo_\(station.id)")

                            Spacer()

                            VStack {
                                MarqueeText(text: station.name, font: .system(size: 15, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        )
                                    )
                                Text(station.frequency)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("直播")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                        }

                        LiveProgressView()
                            .padding(.vertical, 5)

                        HStack(spacing: 18) {
                            Button(action: {
                                shazamManager.isRecognizing ? shazamManager.stopRecognition() : shazamManager.startRecognition()
                            }) {
                                Image(systemName: shazamManager.isRecognizing ? "waveform.and.mic" : "shazam.logo")
                                    .font(.system(size: 20))
                                    .foregroundColor(shazamManager.isRecognizing ? .blue : .secondary)
                                    .symbolEffect(.bounce, options: .repeating, value: shazamManager.isRecognizing)
                            }

                            let isFav = favManager.isFavorite(station)
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                    favManager.toggleFavorite(station)
                                }
                            }) {
                                Image(systemName: isFav ? "heart.fill" : "heart")
                                    .foregroundColor(isFav ? .red : .gray)
                                    .scaleEffect(isFav ? 1.2 : 1.0)
                            }

                            Spacer()

                            Button(action: { playerManager.previous() }) {
                                Image(systemName: "backward.fill")
                            }

                            ZStack {
                                if playerManager.isBuffering {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Button(action: { playerManager.toggle() }) {
                                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                    }
                                }
                            }
                            .frame(width: 30)

                            Button(action: { playerManager.next() }) {
                                Image(systemName: "forward.fill")
                            }

                            Spacer()

                            Button(action: {}) {
                                Image(systemName: "list.bullet")
                            }

                            Button(action: {
                                onSleepTimerTap()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "moon.stars.fill")
                                    if sleepManager.isActive {
                                        Text(sleepManager.formattedRemainingTime)
                                            .font(.system(size: 8, design: .monospaced))
                                    }
                                }
                                .foregroundColor(sleepManager.isActive ? .purple : .gray)
                                .padding(8)
                                .background(Color.purple.opacity(sleepManager.isActive ? 0.1 : 0))
                                .cornerRadius(8)
                            }
                        }
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .padding(.top, 2)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
                .id(station.id)
            }
        }
        .animation(.spring(), value: playerManager.currentStation?.id)
    }

    private func startRotate() {
        angle = 0
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            angle = 360
        }
    }
}
