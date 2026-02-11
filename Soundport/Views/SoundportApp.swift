//
//  SoundportApp.swift
//  Soundport
//
//  Created by dengjinlang on 2026/1/31.
//

import SwiftUI

@main
struct SoundportApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RadioHomeView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // 这里不需要写额外逻辑，Scene Manifest 里的配置会自动引导系统
}
