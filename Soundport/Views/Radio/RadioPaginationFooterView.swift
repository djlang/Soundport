//
//  RadioPaginationFooterView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI

struct RadioPaginationFooterView: View {
    let isFetchingMore: Bool
    let loadError: Bool
    let canLoadMore: Bool
    let onRetry: () -> Void
    let onLoadMore: () -> Void

    var body: some View {
        Group {
            if isFetchingMore {
                HStack {
                    Spacer()
                    ProgressView("正在加载更多...")
                    Spacer()
                }
            } else if loadError {
                Button(action: onRetry) {
                    HStack {
                        Spacer()
                        VStack(spacing: 5) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("加载失败，点击重试")
                                .font(.footnote)
                        }
                        Spacer()
                    }
                }
                .foregroundColor(.secondary)
            } else if !canLoadMore {
                HStack {
                    Spacer()
                    Text("— 已显示全部电台 —")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                Color.clear
                    .frame(height: 50)
                    .onAppear {
                        onLoadMore()
                    }
            }
        }
    }
}
