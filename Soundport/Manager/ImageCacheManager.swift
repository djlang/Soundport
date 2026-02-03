//
//  ImageCacheManager.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/2.
//

import SwiftUI

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private init() {}

    // 内存缓存
    private var memoryCache = NSCache<NSString, UIImage>()

    func get(forKey key: String) -> UIImage? {
        // 1. 先从内存找
        if let image = memoryCache.object(forKey: key as NSString) {
            return image
        }
        // 2. 再从磁盘找
        if let image = getFromDisk(forKey: key) {
            // 存回内存方便下次使用
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        return nil
    }

    func set(_ image: UIImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        saveToDisk(image, forKey: key)
    }

    private func getFilePath(forKey key: String) -> URL? {
        let fileName = HashManager.md5(key) // 建议对URL做哈希处理作为文件名
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    private func saveToDisk(_ image: UIImage, forKey key: String) {
        guard let data = image.pngData(), let url = getFilePath(forKey: key) else { return }
        try? data.write(to: url)
    }

    private func getFromDisk(forKey key: String) -> UIImage? {
        guard let url = getFilePath(forKey: key), let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

// 简单的哈希工具，防止文件名包含特殊字符导致无法保存
struct HashManager {
    static func md5(_ string: String) -> String {
        return String(string.hashValue) // 简化处理，实际开发建议用真正的MD5
    }
}

struct CachedImage<Content: View, Placeholder: View>: View {
    @State private var uiImage: UIImage?
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
        Group {
            if let uiImage = uiImage {
                content(Image(uiImage: uiImage))
                    .transition(.opacity.animation(.easeIn))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        
        // 1. 检查缓存
        if let cached = ImageCacheManager.shared.get(forKey: urlString) {
            self.uiImage = cached
            return
        }

        // 2. 异步下载
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                // 3. 存入缓存
                ImageCacheManager.shared.set(image, forKey: urlString)
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
        }.resume()
    }
}
