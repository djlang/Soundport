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
        manager.startUpdatingLocation()
    }

    // 代理方法：当位置更新时调用
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 1. 获取经纬度 Double 原值
        let latitude = location.coordinate.latitude   // 23.10002707
        let longitude = location.coordinate.longitude // 113.33242424
        
        // 2. 格式化为和风天气要求的字符串 "经度,纬度"
        // 注意：和风建议保留两位小数，或者直接传
        locationString = String(format: "%.2f,%.2f", longitude, latitude)
        
        print("准备请求天气的坐标: \(locationString ?? "113.33,23.10")")
        
        // 3. 停止定位以省电（如果你只需要获取一次当前位置）
        manager.stopUpdatingLocation()
        
        // 4. 调用你的请求函数
        // fetchWeather(at: locationString)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }
}
