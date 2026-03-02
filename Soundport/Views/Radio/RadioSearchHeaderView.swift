//
//  RadioSearchHeaderView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI

struct RadioSearchHeaderView: View {
    @Binding var showSearchSheet: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            Text("搜索电台...")
            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
        .foregroundColor(.secondary)
        .onTapGesture { showSearchSheet = true }
        .sheet(isPresented: $showSearchSheet) {
            SearchView()
        }
    }
}
