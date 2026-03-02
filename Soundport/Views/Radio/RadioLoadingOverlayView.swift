//
//  RadioLoadingOverlayView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI

struct RadioLoadingOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            ProgressView("正在连接广播站...")
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
        }
    }
}
