//
//  SearchView.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) var dismiss // 用于关闭页面
    @StateObject private var viewModel = HomeViewModel() // 或者共用单例
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @ObservedObject private var favManager = FavoritesManager.shared

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isSearching {
                    HStack {
                        Spacer()
                        ProgressView("正在打捞电台...")
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                 // 使用 VStack 配合 Spacer 实现垂直和水平居中
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("没有搜到相关电台")
                                .font(.headline)
                            Text("尝试换个词，比如“广东”或频率")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear) // 去掉列表行的背景，让居中更纯净
                    .frame(maxWidth: .infinity, minHeight: 300) // 确保容器撑开
                } else {
                    ForEach(viewModel.searchResults) { station in
                        StationRow(station: station)
                            .onTapGesture {
                                playerManager.play(station: station)
                            }
                    }
                }
            }
            .navigationTitle("搜索电台")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "输入地名、台名或频率")
            .onChange(of: viewModel.searchText) { _ in
                Task {
                    await viewModel.performSearch()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
