//
//  RadioHomeView.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/10.
//

import SwiftUI
import Combine
import QWeatherSDK

struct RadioHomeView: View {
    private let miniPlayerHeight: CGFloat = 140
    @StateObject private var viewModel = RadioViewModel.shared
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @StateObject private var favManager = FavoritesManager.shared
    
    @State private var showSearchSheet = false
    @State private var showSleepTimerSheet = false
    @ObservedObject var sleepManager = SleepTimerManager.shared
    
    @StateObject private var shazamManager = ShazamManager()
    @State private var angle: Double = 0
    
    
    @StateObject private var wvm = WeatherViewModel()
    @StateObject var locationManager = LocationManager()
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    // 1. 左侧分类导航栏
                    leftSidebar
                    // 2. 右侧电台内容区
                    rightStationContent
                }
                
                // 3. 底部播放器
                if playerManager.currentStation != nil {
                    miniPlayer
                        .transition(.move(edge: .bottom))
                        .zIndex(2)
                }
                
                // 4. 全局加载状态
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("声泊电台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {

                    VStack {
                        HStack {
                            Text("\(wvm.cityName ?? "")")
                                .font(.system(size: 10))
                            Image("\(wvm.weatherNow?.now.icon ?? "100")")
                                .resizable()
                                .frame(width: 12, height: 12)
                        }

                        Text("\(wvm.weatherNow?.now.temp ?? "20")°C \(wvm.weatherNow?.now.text ?? "")" )
                            .font(.system(size: 10))
                       
                    }
                    
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
            
            Task{
                await wvm.fetchWeatherNow(location: locationManager.locationString ?? "113.33,23.10")
            }
        }
    }
    
    // MARK: - 子组件：左侧分类导航
    private var leftSidebar: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(RadioCategory.allCases) { category in
                    let isSelected = viewModel.selectedCategory == category
                    
                    VStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .blue : .gray)
                        
                        // 如果是地区分类，显示具体的省份名（如：广东）
                        Text(category == .region ? viewModel.selectedProvince : (category == .country ? viewModel.selectedCountry : category.rawValue))
                            .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? .blue : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 75)
                    .background(isSelected ? Color(UIColor.systemBackground) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if category == .region && viewModel.selectedCategory == .region {
                            // 如果已经在地区页，再次点击弹出省份选择
                            viewModel.showProvincePicker = true
                        } else if category == .country && viewModel.selectedCategory == .country {
                            viewModel.showCountryPicker = true
                        }
                        
                        else {
                            Task {
                                await viewModel.selectCategory(category)
                            }
                        
                        }
                        
                    }
                    
                    Divider().padding(.horizontal, 10).opacity(0.3)
                }
            }
            .padding(.top, 10)
            
            // 避开播放器遮挡
            Spacer(minLength: miniPlayerHeight)
        }
        .frame(width: 85)
        .background(Color(UIColor.systemGray6).opacity(0.8))
        .overlay(Divider(), alignment: .trailing)
    }
    
    // MARK: - 子组件：右侧列表内容
    private var rightStationContent: some View {
        VStack(spacing: 0) {
            // 伪搜索框
            searchBarHeader
            
            if viewModel.stations.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                List {
                    // 当前分类标题头
                    Section(header: Text(viewModel.selectedCategory == .region ? viewModel.selectedProvince : (viewModel.selectedCategory == .country ? viewModel.selectedCountry : viewModel.selectedCategory.rawValue)).font(.subheadline)) {
                        ForEach(viewModel.stations) { station in
                            StationRow(station: station)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    playerManager.play(station: station)
                                }
                        }
                    }
                    
                    // 2. 翻页加载触发器 (关键位置)
                    // --- 翻页/底部状态区 ---
                    if !viewModel.stations.isEmpty && viewModel.selectedCategory != .favorites {
                        Group {
                            if viewModel.isFetchingMore {
                                // 1. 正在加载中
                                HStack {
                                    Spacer()
                                    ProgressView("正在加载更多...")
                                    Spacer()
                                }
                            } else if viewModel.loadError {
                                // 2. 加载失败，点击重试
                                Button(action: {
                                    viewModel.loadError = false
                                    Task { await viewModel.loadData(isNextPage: true) }
                                }) {
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 5) {
                                            Image(systemName: "exclamationmark.triangle")
                                            Text("加载失败，点击重试").font(.footnote)
                                        }
                                        Spacer()
                                    }
                                }
                                .foregroundColor(.secondary)
                            } else if !viewModel.canLoadMore {
                                // 3. 加载到最后了
                                HStack {
                                    Spacer()
                                    Text("— 已显示全部电台 —")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            } else {
                                // 4. 准备加载触发器：这是一个看不见的透明层，滑动到它时触发
                                Color.clear
                                    .frame(height: 50)
                                    .onAppear {
                                        Task { await viewModel.loadData(isNextPage: true) }
                                    }
                            }
                        }
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 10)
                    }
                    
                    // 底部占位
                    Color.clear.frame(height: miniPlayerHeight).listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var searchBarHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            Text("搜索电台...")
            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
        .foregroundColor(.secondary)
        .onTapGesture { showSearchSheet = true }
        .sheet(isPresented: $showSearchSheet) {
            SearchView()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: viewModel.selectedCategory == .favorites ? "heart.slash" : "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text(viewModel.selectedCategory == .favorites ? "暂无收藏电台" : "该分类暂无数据")
                .foregroundColor(.secondary)
            if viewModel.selectedCategory == .favorites {
                Text("点击电台后的红心即可收藏").font(.caption2).foregroundColor(.gray)
            }
            Spacer()
        }
    }

    // MARK: - 其他原有组件逻辑（保持不变或微调）
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.05).ignoresSafeArea()
            ProgressView("正在连接广播站...")
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
        }
    }

    private var miniPlayer: some View {
        Group {
            if let station = playerManager.currentStation {
                VStack(spacing: 0) {
                    Divider()
                    VStack {
                        HStack(spacing: 15) {
                            // Logo 动画
                            CachedImage(url: station.logoUrl) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
//                                Image(systemName: "radio").foregroundColor(.blue.opacity(0.5))
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
                                MarqueeText(text: station.name,font: .system(size: 15, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                           removal: .move(edge: .leading).combined(with: .opacity)))
                                Text(station.frequency)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // “直播” 标志
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
                        
                        LiveProgressView().padding(.vertical, 5)
                        
                        HStack(spacing: 18) {
                            // 🎵 音乐识别按钮
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
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { // 加个跳动动画
                                    favManager.toggleFavorite(station)
                                    
                                }
                                
                            }) {
                                Image(systemName: isFav ? "heart.fill" : "heart")
                                    .foregroundColor(isFav ? .red : .gray)
                                    .scaleEffect(isFav ? 1.2 : 1.0) // 收藏后稍微放大，更有质感
                            }
                            
                            Spacer()
                            Button(action: { playerManager.previous() }) {
                                Image(systemName: "backward.fill")
                            }
                            
                            
                            ZStack {
                                if playerManager.isBuffering {
                                    ProgressView()
                                        .controlSize(.small)
                                }else {
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
                            
                            Button(action: { /* 列表 */ }) {
                                Image(systemName: "list.bullet")
                            }
                            
                            if playerManager.currentStation != nil {
                                Button(action: {
                                    // 弹出睡眠选择菜单
                                    showSleepTimerSheet = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "moon.stars.fill")
                                        if sleepManager.isActive {
                                            Text(sleepManager.formattedRemainingTime)
                                                .font(.system(size: 10, design: .monospaced))
                                        }
                                    }
                                    .foregroundColor(sleepManager.isActive ? .purple : .gray)
                                    .padding(8)
                                    .background(Color.purple.opacity(sleepManager.isActive ? 0.1 : 0))
                                    .cornerRadius(8)
                                }
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


struct RadioHomeView_Previews: PreviewProvider {
    static var previews: some View {
        RadioHomeView()
    }
}
