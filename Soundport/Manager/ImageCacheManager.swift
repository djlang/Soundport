//
//  ImageCacheManager.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/2.
//

import SwiftUI
import SDWebImageSwiftUI // 确保已安装并引入

struct CachedImage<Content: View, Placeholder: View>: View {
    let urlString: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    init(
        url: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        // 使用 WebImage 的闭包构造器 (方案二)
        WebImage(url: URL(string: urlString ?? "")) { image in
            // 成功加载：调用传入的 content 闭包
            // 注意：image 已经是 SDWebImage 处理好的 Image 对象
            content(image)
        } placeholder: {
            // 加载中或失败：调用传入的 placeholder 闭包
            placeholder()
        }
        .onSuccess { image, data, cacheType in
            print("✅ SVG 加载成功: \(urlString ?? "")")
        }
        .onFailure { error in
            // 关键：在控制台看具体错误
            print("❌ 图片加载失败: \(urlString ?? ""), 错误原因: \(error.localizedDescription)")
            if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError {
                print("🔍 底层错误码: \(underlyingError.code), 描述: \(underlyingError.localizedDescription)")
            }
        }
        // 以下是全局配置
        .retryOnAppear(true)               // 视图出现时如果失败则重试
        .transition(.fade(duration: 0.3)) // 图片出现时的平滑淡入
//        .indicator(.activity)             // 可选：加载时的菊花转圈
    }
}
