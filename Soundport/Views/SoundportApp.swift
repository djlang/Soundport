//
//  SoundportApp.swift
//  Soundport
//
//  Created by dengjinlang on 2026/1/31.
//

import SwiftUI
import SDWebImage
import SDWebImageSVGCoder

@main
struct SoundportApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        // 关键步骤：注册 SVG 解码器
        let SVGCoder = SDImageSVGCoder.shared
        SDImageCodersManager.shared.addCoder(SVGCoder)
        SDWebImageDownloader.shared.setValue("image/svg+xml,image/*;q=0.8", forHTTPHeaderField: "Accept")
            
    }
    
    var body: some Scene {
        WindowGroup {
            RadioHomeView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // 这里不需要写额外逻辑，Scene Manifest 里的配置会自动引导系统
}
