//
//  LocationManager.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/27.
//

import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var isMonitoringSignificantChanges = false
    
    // 发布位置数据，供 SwiftUI 视图监听
//    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationString: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest // 设置精度
    }

    func requestLocation() {
        // 检查权限并请求位置
        manager.requestWhenInUseAuthorization()
        // 先请求一次当前位置
        manager.requestLocation()
        // 低功耗监听显著位置变化，避免持续高频定位
        startMonitoringSignificantChangesIfNeeded()
    }

    // 代理方法：当位置更新时调用
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 1. 获取经纬度 Double 原值
        let latitude = location.coordinate.latitude   // 23.10002707
        let longitude = location.coordinate.longitude // 113.33242424
        
        // 2. 格式化为和风天气要求的字符串 "经度,纬度"
        // 注意：和风建议保留两位小数，或者直接传
        let newLocationString = String(format: "%.2f,%.2f", longitude, latitude)
        DispatchQueue.main.async {
            self.locationString = newLocationString
        }
        
        print("准备请求天气的坐标: \(newLocationString)")
        
        // 3. 停止普通定位以省电（显著变化监听继续生效）
        manager.stopUpdatingLocation()
        
        // 4. 调用你的请求函数
        // fetchWeather(at: locationString)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        // 授权后启动显著位置变化监听
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
            startMonitoringSignificantChangesIfNeeded()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失败: \(error.localizedDescription)")
    }

    private func startMonitoringSignificantChangesIfNeeded() {
        guard !isMonitoringSignificantChanges else { return }
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
        manager.startMonitoringSignificantLocationChanges()
        isMonitoringSignificantChanges = true
    }
}
