import SwiftUI

struct MainHomeView: View {
    private let miniPlayerHeight: CGFloat = 100
//    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var viewModel = HomeViewModel.shared
    // 关键：将 currentStation 逻辑交给 playerManager 统一管理，确保 UI 状态同步
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @State private var showSearchSheet = false
    
    @State private var showSleepTimerSheet = false
    @ObservedObject var sleepManager = SleepTimerManager.shared
    
    @StateObject private var shazamManager = ShazamManager()
    
    var body: some View {
        // 使用 NavigationView 提供顶部标题栏空间
        NavigationView {
            ZStack(alignment: .bottom) {
                
//                // 背景层：放一个渐变色，透过侧边栏会非常漂亮
//                LinearGradient(
//                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//                .ignoresSafeArea()
                HStack(spacing: 0) {
                    //  左侧地区导航栏
                    leftSidebar
                    //  右侧电台列表
                    rightStationList
                }
                 //底部播放
                if playerManager.currentStation != nil {
                    miniPlayer // 不再需要传参 (for: station)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
                // 全局加载状态遮罩
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            // 设置顶部导航标题
            .navigationTitle("声泊电台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            .sheet(isPresented: $showSleepTimerSheet) {
                SleepTimerSheet()
            }
            
        }
        .navigationViewStyle(.stack) // 适配不同尺寸屏幕
        .onAppear {
            Task {
                await viewModel.loadAllData()
            }
        }
     
    }
    
    // --- 子组件：左侧导航 ---
    private var leftSidebar: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if let _ = viewModel.favoriteRegion {
                    let isFavSelected = viewModel.selectedRegionId == "favorites_group"
                    VStack(spacing: 4) {
                        Image(systemName: isFavSelected ? "heart.fill" : "heart")
                            .foregroundColor(isFavSelected ? .red : .gray)
                        Text("收藏")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isFavSelected ? .red : .primary)
                    }
                    .frame(maxWidth: .infinity).frame(height: 70)
                    .background(isFavSelected ? Color.white : Color.clear)
                    .onTapGesture {
                        viewModel.isManualClick = true
                        viewModel.selectedRegionId = "favorites_group"
                        // 延时重置
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.isManualClick = false
                        }
                    }
                }
                ForEach(viewModel.regions) { region in
                    let isSelected = viewModel.selectedRegionId == region.id
                    Text(region.name)
                        .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(isSelected ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6))
                        .onTapGesture {
                            viewModel.isManualClick = true
                            viewModel.selectedRegionId = region.id
                            // 延时释放，等待右侧滚动动画完成
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.isManualClick = false
                            }
                        }
                }
            }
        }
        .frame(width: 100)
        .background(
            Rectangle()
            .fill(.ultraThinMaterial)
        )
        .overlay(
            Divider().offset(x: 1), // 在右侧加一条细线
            alignment: .trailing
        )
        
    }
    
    // --- 子组件：右侧列表 ---
    private var rightStationList: some View {
        VStack {
            // 伪搜索框：点击弹出真正搜索页
            HStack {
                Image(systemName: "magnifyingglass")
                Text("搜索电台...")
                Spacer()
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            .foregroundColor(.secondary)
            .onTapGesture {
                showSearchSheet = true
            }
            ScrollViewReader { proxy in
                List {
                    if let favRegion = viewModel.favoriteRegion {
                        Section(header: Text(favRegion.name).font(.headline).id("favorites_group")) {
                            ForEach(favRegion.stations) { station in
                                StationRow(station: station)
                                    .onTapGesture { playerManager.play(station: station) }
                            }
                        }
                    }
                    ForEach(viewModel.regions) { region in
                        Section(header: Text(region.name).font(.headline).id(region.id)) {
                            ForEach(region.stations) { station in
                                StationRow(station: station)
                                    .contentShape(Rectangle()) // 确保整行可点
                                    .onTapGesture {
                                        // 直接调用单例播放
                                        playerManager.play(station: station)
                                    }
                                    .onAppear {
                                        // 反向联动：滑动列表自动切换左侧高亮
                                        if !viewModel.isManualClick && station == region.stations.first {
                                            viewModel.selectedRegionId = region.id
                                        }
                                    }
                            }
                        }
                    }
                    
                    Color.clear
                        .frame(height: playerManager.currentStation != nil ? miniPlayerHeight : 0)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .onChange(of: viewModel.selectedRegionId) { newValue in
                    if viewModel.isManualClick {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            proxy.scrollTo(newValue, anchor: .top)
                        }
                    }
                }
                .onChange(of: playerManager.currentStation) { newStation in
                    if let station = newStation {
                        // 找到该电台所属的 regionId，触发列表滚动
                        if let region = viewModel.regions.first(where: { $0.stations.contains(where: { $0.id == station.id }) }) {
                            withAnimation {
                                proxy.scrollTo(region.id, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            SearchView()
        }
        
    }
    
    // --- 子组件：加载遮罩 ---
    private var loadingOverlay: some View {
        ProgressView("正在连接广播....")
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
    
    // --- 子组件：底部播控条 ---
    private var miniPlayer: some View {
        // 使用 Group 配合 id 绑定，当 station.id 变化时触发动画
        Group {
            if let station = playerManager.currentStation {
                VStack(spacing: 0) {
                    Divider()
                    VStack {
                        HStack(spacing: 15) {
                            // --- 1. Logo 部分 ---
                            CachedImage(url: station.logoUrl) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                ZStack {
                                    Color.blue.opacity(0.1)
                                    Image(systemName: "radio").foregroundColor(.blue.opacity(0.5))
                                }
                            }
                            .frame(width: 40, height: 40)
                            .cornerRadius(25)
                            .clipped()
                            // 给图片加个标识，切换时有淡入淡出
                            .id("logo_\(station.id)")
                            
                            VStack {
                                // --- 2. 文字部分 ---
                                Text(station.name)
                                    .font(.system(size: 15, weight: .bold))
                                    .lineLimit(1)
                                    // 关键：当 ID 变化时，应用推入动画
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
                        
                        LiveProgressView()
                            .padding(.horizontal)
                        
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
                            
                            let isFav = FavoritesManager.shared.favoriteIDs.contains(station.id)
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { // 加个跳动动画
                                    FavoritesManager.shared.toggleFavorite(stationID: station.id)
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
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.vertical, 10)
                    .padding(.bottom, 34)
                    .background(.ultraThinMaterial)
                }
                .contentShape(Rectangle())
                // 核心动画：当电台 ID 改变时，整个内容块平滑过渡
                .id(station.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerManager.currentStation?.id)
    }
}

struct MainHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MainHomeView()
    }
}
