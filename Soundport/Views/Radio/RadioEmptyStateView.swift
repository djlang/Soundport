//
//  RadioEmptyStateView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI

struct RadioEmptyStateView: View {
    let selectedCategory: RadioCategory

    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: selectedCategory == .favorites ? "heart.slash" : "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text(selectedCategory == .favorites ? "暂无收藏电台" : "该分类暂无数据")
                .foregroundColor(.secondary)
            if selectedCategory == .favorites {
                Text("点击电台后的红心即可收藏")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
}
