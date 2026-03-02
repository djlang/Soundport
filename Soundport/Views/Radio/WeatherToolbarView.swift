//
//  WeatherToolbarView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI
import QWeatherSDK

struct WeatherToolbarView: View {
    @ObservedObject var weatherViewModel: WeatherViewModel

    var body: some View {
        VStack {
            HStack {
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
