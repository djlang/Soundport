//
//  CacheManager.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//

import Foundation
import SDWebImage

struct CacheManager {
    static let filename = "radio_data_v1.json"
    
    private static var cacheURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(filename)
    }
    
    // 获取缓存大小 (MB)
    static func calculateCacheSize() -> String {
        var totalSize: UInt64 = 0
        
        // 1. JSON 缓存大小
        if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
           let fileSize = attributes[.size] as? UInt64 {
            totalSize += fileSize
        }
        
        // 2. SDImageCache 大小
        totalSize += UInt64(SDImageCache.shared.totalDiskSize())
        
        let sizeMB = Double(totalSize) / 1024 / 1024
        return String(format: "%.1f", sizeMB)
    }
    
    // 清除所有缓存
    static func clearAllCache(completion: @escaping () -> Void) {
        // 1. 清除 JSON 缓存
        try? FileManager.default.removeItem(at: cacheURL)
        
        // 2. 清除 SDImageCache
        SDImageCache.shared.clearDisk {
            completion()
        }
    }
    
    // 异步保存：不阻塞主线程，真机更流畅
    static func saveToCache(_ regions: [Region]) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let encoder = JSONEncoder()
                // 增加校验，确保数据不为空才覆盖旧缓存
                guard !regions.isEmpty else { return }
                let data = try encoder.encode(regions)
                
                // .atomic 确保文件写入完整，不会产生损坏的半截文件
                try data.write(to: cacheURL, options: .atomic)
                print("💾 [真机缓存] 成功存入 \(regions.count) 个分组")
            } catch {
                print("❌ [真机缓存] 写入失败: \(error)")
            }
        }
    }
    
    static func loadFromCache() -> [Region]? {
        // 真机检查文件是否存在
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            print("⚠️ [真机缓存] 未找到缓存文件")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let regions = try JSONDecoder().decode([Region].self, from: data)
            print("📖 [真机缓存] 成功加载 \(regions.count) 个分组")
            return regions
        } catch {
            print("❌ [真机缓存] 读取/解析失败: \(error)")
            // 如果解析失败，说明缓存文件损坏，建议删除
            try? FileManager.default.removeItem(at: cacheURL)
            return nil
        }
    }
}
//struct CacheManager {
//    static let filename = "radio_regions_cache.json"
//    
//    // 获取缓存文件的路径
//    private static var cacheURL: URL {
//        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        return paths[0].appendingPathComponent(filename)
//    }
//    
//    // 保存数据到本地
//    static func saveToCache(_ regions: [Region]) {
//        DispatchQueue.global(qos: .background).async {
//            do {
//                let data = try JSONEncoder().encode(regions)
//                try data.write(to: cacheURL)
//                print("💾 [Cache] 数据已缓存至本地")
//            } catch {
//                print("❌ [Cache] 保存失败: \(error)")
//            }
//        }
//    }
//    
//    // 从本地读取数据
//    static func loadFromCache() -> [Region]? {
//        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return nil }
//        do {
//            let data = try Data(contentsOf: cacheURL)
//            let regions = try JSONDecoder().decode([Region].self, from: data)
//            print("📖 [Cache] 成功从本地加载了 \(regions.count) 个分组")
//            return regions
//        } catch {
//            print("❌ [Cache] 读取失败: \(error)")
//            return nil
//        }
//    }
//}
