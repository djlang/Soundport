//
//  RadioHomeView.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/10.
//

import SwiftUI

struct RadioHomeView: View {
    private let miniPlayerHeight: CGFloat = 140
    @StateObject private var viewModel = RadioViewModel.shared
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    
    @State private var showSearchSheet = false
    @State private var showSleepTimerSheet = false

    @StateObject private var wvm = WeatherViewModel()
    @StateObject var locationManager = LocationManager()
    @State private var lastWeatherLocation: String?
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    RadioCategorySidebarView(
                        selectedCategory: viewModel.selectedCategory,
                        selectedProvince: viewModel.selectedProvince,
                        selectedCountry: viewModel.selectedCountry,
                        miniPlayerHeight: miniPlayerHeight,
                        onCategoryTap: { category in
                            Task {
                                await viewModel.selectCategory(category)
                            }
                        },
                        onRepeatRegionTap: {
                            viewModel.showProvincePicker = true
                        },
                        onRepeatCountryTap: {
                            viewModel.showCountryPicker = true
                        }
                    )
                    RadioStationContentView(
                        viewModel: viewModel,
                        showSearchSheet: $showSearchSheet,
                        miniPlayerHeight: miniPlayerHeight,
                        onStationTap: { station in
                            playerManager.play(station: station)
                        }
                    )
                }
                
                // 3. 底部播放器
                if playerManager.currentStation != nil {
                    RadioMiniPlayerView(
                        onSleepTimerTap: {
                            showSleepTimerSheet = true
                        }
                    )
                        .transition(.move(edge: .bottom))
                        .zIndex(2)
                }
                
                // 4. 全局加载状态
                if viewModel.isLoading {
                    RadioLoadingOverlayView()
                }
            }
            .navigationTitle("声泊电台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    WeatherToolbarView(weatherViewModel: wvm)
                }
            }
            .sheet(isPresented: $showSleepTimerSheet) {
                SleepTimerSheet()
            }
            // 地区选择弹出层
            .sheet(isPresented: $viewModel.showProvincePicker) {
                ProvincePickerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showCountryPicker) {
                CountryPickerView(viewModel: viewModel)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            locationManager.requestLocation()
        }
        .task(id: locationManager.locationString) {
            guard let location = locationManager.locationString else { return }
            guard lastWeatherLocation != location else { return }
            lastWeatherLocation = location
            await wvm.fetchWeatherNow(location: location)
        }
    }
}


struct RadioHomeView_Previews: PreviewProvider {
    static var previews: some View {
        RadioHomeView()
    }
}
