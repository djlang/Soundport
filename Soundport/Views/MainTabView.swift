//
//  MainTabView.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/5.
//
import SwiftUI
import Combine

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 接入你现有的电台页面
            // 假设你之前的入口是 HomeView()
            RadioHomeView()
                .tabItem {
                    Label("电台", systemImage: "radio")
                }
                .tag(0)
            
            // Tab 2: 电视页面（先占位，确保框架跑通）
            TVHomeView()
                .tabItem {
                    Label("电视", systemImage: "tv")
                }
                .tag(1)
        }
        // 建议加上这一行，解决某些 iOS 版本 TabBar 变透明的问题
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
}
