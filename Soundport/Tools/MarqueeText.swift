//
//  Untitled.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/12.
//

import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let speed: Double = 40.0
    
    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { containerGeometry in
            ZStack {
                if contentWidth <= containerWidth {
                    // 情况 A：文字短，居中显示
                    Text(text)
                        .font(font)
                        .lineLimit(1)
                        .position(x: containerGeometry.size.width / 2, y: containerGeometry.size.height / 2)
                } else {
                    // 情况 B：文字长，开启滚动
                    Text(text)
                        .font(font)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .offset(x: offset)
                }
                
                // 隐藏的测量层：实时测量文字宽度
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .opacity(0)
                    .background(GeometryReader { proxy in
                        Color.clear.onAppear {
                            updateWidths(content: proxy.size.width, container: containerGeometry.size.width)
                        }
                    })
            }
        }
        .frame(height: 25)
        .clipped()
        .mask(
            HStack(spacing: 0) {
                // 左边缘淡入
                LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                    .frame(width: 10)
                // 中间完全显示
                Rectangle().fill(Color.black)
                // 右边缘淡出
                LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                    .frame(width: 10)
            }
        )
        // 关键：当文字内容变化或宽度变化时，重新检查动画
        .onChange(of: text) { _ in resetAnimation() }
        .onChange(of: contentWidth) { _ in resetAnimation() }
    }

    private func updateWidths(content: CGFloat, container: CGFloat) {
        contentWidth = content
        containerWidth = container
        if contentWidth > containerWidth {
            startAnimation()
        }
    }

    private func startAnimation() {
        // 防止重复启动动画
        guard !isAnimating && contentWidth > containerWidth else { return }
        isAnimating = true
        
        // 动画逻辑：从右边缘外开始，滚动到左边缘外消失
        let totalDistance = contentWidth + containerWidth
        let duration = Double(totalDistance) / speed
        
        // 1. 先把位置重置到最右侧（容器边缘）
        offset = containerWidth
        
        // 2. 执行线性循环动画
        withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -contentWidth
        }
    }
    
    private func resetAnimation() {
        isAnimating = false
        offset = 0
        // 延迟给一点时间让 SwiftUI 完成布局渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startAnimation()
        }
    }
}
