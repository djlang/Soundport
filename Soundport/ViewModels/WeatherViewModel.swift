//
//  WeatherViewModel.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/27.
//

import SwiftUI
import QWeatherSDK
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    // 发布的属性，当这些值改变时，UI 会自动刷新
    @Published var weatherNow: WeatherNowResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var cityName: String?
    
    private var isConfigured = false
    private var isConfiguring = false

    init() {
        Task {
            await ensureConfigured()
        }
    }

    private func ensureConfigured() async {
        if isConfigured || isConfiguring {
            return
        }
        
        isConfiguring = true
        defer { isConfiguring = false }
        
        do {
            let jwt = JWTGenerator(
                privateKey: "MC4CAQAwBQYDK2VwBCIEIIsQLmaBc47gChaPflzaty8ooXLQxPLJ8mTr2ZFPBAyW",
                pid: "4KTHBBBK24",
                kid: "TNPKEQQEUW"
            )
            
            try await QWeather.getInstance("pu3qqrdrmr.re.qweatherapi.com")
                .setupTokenGenerator(jwt)
                .setupLogEnable(true)
            
            self.isConfigured = true
        } catch {
            self.errorMessage = "SDK 初始化失败: \(error.localizedDescription)"
        }
    }

    // 业务逻辑方法：获取实时天气
    func fetchWeatherNow(location: String = "101280101") async {
        await ensureConfigured()
        guard isConfigured else { return }
        
        isLoading = true
        errorMessage = nil

        do {
            let parameter = WeatherParameter(location: location)
            let response = try await QWeather.instance.weatherNow(parameter)
            print(response)
            self.weatherNow = response
        } catch QWeatherError.errorResponse(let error) {
            self.errorMessage = "API 错误: \(error)"
        } catch {
            self.errorMessage = "未知错误: \(error.localizedDescription)"
        }
        
        isLoading = false
        
        Task {
            await locationToCity(location: location)
        }
    }
    
    // 你可以继续在此添加 testGeoCityLookup, testAirNow 等其他方法
    //通过经纬度查询所在的位置
    func locationToCity(location: String = "101280101") async {
        do {
            let response =  try await QWeather.instance
                .geoCityLookup(.init(location: location))
            print(response)
            self.cityName = response.location.last?.name
        } catch QWeatherError.errorResponse(let error) {
            print(error)
        } catch {
            print(error)
        }
    }
    
    
    
    
    //获取城市id

    func fetchCityCode() {
        Task{
            do {
                let response =  try await QWeather.instance
                    .geoCityLookup(.init(location: "广州"))
                print(response)
            } catch QWeatherError.errorResponse(let error) {
                print(error)
            } catch {
                print(error)
            }
        }
    }
}


/**
 location    [QWeatherSDK.Location]    1 value
 [0]    QWeatherSDK.Location    0x00000001354b0fc0
 ObjectiveC.NSObject    NSObject
 name    String    "海珠"
 cid    String    "101280108"
 lat    String    "23.08400"
 lon    String    "113.31741"
 adm2    String    "广州"
 adm1    String    "广东省"
 country    String    "中国"
 tz    String    "Asia/Shanghai"
 utcOffset    String    "+08:00"
 isDst    String    "0"
 type    String    "city"
 rank    String    "25"
 fxLink    String    "https://www.qweather.com/weather/haizhu-101280108.html"
 */
