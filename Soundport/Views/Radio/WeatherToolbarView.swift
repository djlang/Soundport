import SwiftUI
import QWeatherSDK

// MARK: - 常量定义
private enum Constants {
    static let smallIconSize: CGFloat = 12
    static let smallFontSize: CGFloat = 10
    static let placeholderWidth1: CGFloat = 36
    static let placeholderWidth2: CGFloat = 64
    static let placeholderHeight: CGFloat = 8
    static let cornerRadius: CGFloat = 2
    static let shimmerAnimationDuration: TimeInterval = 1.2
}

struct WeatherToolbarView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var weatherViewModel: WeatherViewModel
    let onTapRefresh: () -> Void
    
    // MARK: - 计算属性
    private var cityName: String {
        weatherViewModel.cityName ?? ""
    }
    
    private var temperatureText: String {
        guard let temp = weatherViewModel.weatherNow?.now.temp,
              let text = weatherViewModel.weatherNow?.now.text else {
            return "--°C --"
        }
        return "\(temp)°C \(text)"
    }
    
    private var iconName: String {
        weatherViewModel.weatherNow?.now.icon ?? "100"
    }
    
    private var hasWeatherLink: Bool {
        weatherViewModel.weatherNow?.fxLink != nil
    }
    
    // MARK: - 主视图
    var body: some View {
        Button(action: handleButtonTap) {
            contentView
        }
        .buttonStyle(.plain)
        .disabled(weatherViewModel.isLoading)
        .contextMenu {
            contextMenuItems
        }
        .onAppear {
            weatherViewModel.updateCacheSize()
        }
    }
    
    // MARK: - 子视图
    private var contentView: some View {
        Group {
            if weatherViewModel.isLoading {
                LoadingPlaceholderView()
            } else if let error = weatherViewModel.errorMessage {
                ErrorStateView(error: error)
            } else {
                WeatherInfoView(
                    cityName: cityName,
                    iconName: iconName,
                    temperatureText: temperatureText
                )
            }
        }
    }
    
    private var contextMenuItems: some View {
        Group {
            Button("更新", systemImage: "arrow.clockwise") {
                onTapRefresh()
            }
            
            if hasWeatherLink {
                Button("详情", systemImage: "info.circle") {
                    openWeatherDetails()
                }
            }
            
            Divider()
            
            Button("清除缓存 (\(weatherViewModel.cacheSize)MB)", systemImage: "trash") {
                weatherViewModel.clearCache()
            }
        }
    }
    
    // MARK: - 操作方法
    private func handleButtonTap() {
        if !weatherViewModel.isLoading && weatherViewModel.errorMessage == nil {
            onTapRefresh()
        }
    }
    
    private func openWeatherDetails() {
        guard let link = weatherViewModel.weatherNow?.fxLink,
              let url = URL(string: link) else { return }
        openURL(url)
    }
}

// MARK: - 加载占位符视图
struct LoadingPlaceholderView: View {
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: Constants.placeholderWidth1,
                           height: Constants.placeholderHeight)
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: Constants.smallIconSize,
                           height: Constants.smallIconSize)
            }
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Color.gray.opacity(0.25))
                .frame(width: Constants.placeholderWidth2,
                       height: Constants.placeholderHeight)
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

// MARK: - 错误状态视图
struct ErrorStateView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .frame(width: Constants.smallIconSize,
                       height: Constants.smallIconSize)
                .foregroundColor(.orange)
            Text("加载失败")
                .font(.system(size: Constants.smallFontSize))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 天气信息视图
struct WeatherInfoView: View {
    let cityName: String
    let iconName: String
    let temperatureText: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Text(cityName)
                    .font(.system(size: Constants.smallFontSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // 使用安全的图片加载方式
                if let image = UIImage(named: iconName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.smallIconSize,
                               height: Constants.smallIconSize)
                } else {
                    // 回退到系统图标
                    Image(systemName: "cloud")
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.smallIconSize,
                               height: Constants.smallIconSize)
                }
            }
            
            Text(temperatureText)
                .font(.system(size: Constants.smallFontSize))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - 视图修饰符
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
            .animation(
                .linear(duration: Constants.shimmerAnimationDuration)
                .repeatForever(autoreverses: false),
                value: UUID()
            )
    }
}
