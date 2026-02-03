//
//  LiveVisualizer.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//

import SwiftUI

struct LiveVisualizer: View {
    @State private var isAnimating = false
    
    // 线条颜色，建议使用主题色或白色
    var color: Color = .blue
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: isAnimating ? CGFloat.random(in: 8...16) : 4)
                    // 为每根线条设置不同的动画延迟，营造随机感
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
