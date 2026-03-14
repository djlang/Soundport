//
//  WeatherToolbarView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI
import QWeatherSDK

struct WeatherToolbarView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var weatherViewModel: WeatherViewModel
    let onTapRefresh: () -> Void

    var body: some View {
        Button(action: onTapRefresh) {
            if weatherViewModel.isLoading {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.25))
                            .frame(width: 36, height: 8)
                        Circle()
                            .fill(Color.gray.opacity(0.25))
                            .frame(width: 12, height: 12)
                    }
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 64, height: 8)
                }
                .redacted(reason: .placeholder)
                .shimmer()
            } else {
                VStack {
                    HStack(spacing: 6) {
                        Text("\(weatherViewModel.cityName ?? "")")
                            .font(.system(size: 10))
                        Image("\(weatherViewModel.weatherNow?.now.icon ?? "100")")
                            .resizable()
                            .frame(width: 12, height: 12)
                    }

                    Text("\(weatherViewModel.weatherNow?.now.temp ?? "20")°C \(weatherViewModel.weatherNow?.now.text ?? "")")
                        .font(.system(size: 10))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(weatherViewModel.isLoading)
        .contextMenu {
            Button("更新") {
                onTapRefresh()
            }
            Button("详情") {
                guard let link = weatherViewModel.weatherNow?.fxLink,
                      let url = URL(string: link) else { return }
                openURL(url)
            }
        }
    }
}

private extension View {
    func shimmer() -> some View {
        self
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .mask(self)
            )
            .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: UUID())
    }
}
