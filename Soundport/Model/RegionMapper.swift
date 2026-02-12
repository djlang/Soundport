//
//  RegionMapper.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/10.
//

import Foundation

struct RegionMapper {
    
    /// 1. 核心转换字典：涵盖邮政式拼音、标准拼音及常见英文名
    private static let translationMap: [String: String] = [
        // --- 华南地区 ---
        "Kwangtung": "广东", "Guangdong": "广东", "Canton": "广东",
        "Kwangsi": "广西", "Guangxi": "广西",
        "Fukien": "福建", "Fujian": "福建",
        "Hainan": "海南",
        
        // --- 港澳台 (重点兼容各种缩写) ---
        "Hong Kong": "香港", "HK": "香港", "Hongkong": "香港", "Hong Kong SAR": "香港",
        "Macau": "澳门", "Macao": "澳门", "MO": "澳门", "Macau SAR": "澳门",
        "Taiwan": "台湾", "TW": "台湾", "Republic of China": "台湾", "Chinese Taipei": "台湾",

        // --- 华东地区 ---
        "Kiangsu": "江苏", "Jiangsu": "江苏",
        "Chekiang": "浙江", "Zhejiang": "浙江",
        "Anhwei": "安徽", "Anhui": "安徽",
        "Kiangsi": "江西", "Jiangxi": "江西",
        "Shantung": "山东", "Shandong": "山东",
        "Shanghai": "上海",

        // --- 华北地区 ---
        "Hopei": "河北", "Hebei": "河北",
        "Shansi": "山西", "Shanxi": "山西",
        "Inner Mongolia": "内蒙古", "Nei Mongol": "内蒙古", "Neimenggu": "内蒙古",
        "Peking": "北京", "Beijing": "北京",
        "Tientsin": "天津", "Tianjin": "天津",

        // --- 华中地区 ---
        "Honan": "河南", "Henan": "河南",
        "Hupeh": "湖北", "Hubei": "湖北", "Hupei": "湖北",
        "Hunan": "湖南",

        // --- 西南地区 ---
        "Szechwan": "四川", "Sichuan": "四川", "Szechuan": "四川",
        "Kweichow": "贵州", "Guizhou": "贵州",
        "Yunnan": "云南",
        "Tibet": "西藏", "Xizang": "西藏",
        "Chungking": "重庆", "Chongqing": "重庆",

        // --- 西北地区 ---
        "Shensi": "陕西", "Shaanxi": "陕西",
        "Kansu": "甘肃", "Gansu": "甘肃",
        "Tsinghai": "青海", "Qinghai": "青海",
        "Ninghsia": "宁夏", "Ningxia": "宁夏", "Ningsia": "宁夏",
        "Sinkiang": "新疆", "Xinjiang": "新疆",

        // --- 东北地区 ---
        "Liaoning": "辽宁",
        "Kirin": "吉林", "Jilin": "吉林",
        "Heilungkiang": "黑龙江", "Heilongjiang": "黑龙江",
        
        // --- 全球常用 (可选) ---
        "United States": "美国", "USA": "美国",
        "United Kingdom": "英国", "UK": "英国", "Great Britain": "英国",
        "Japan": "日本", "Korea": "韩国", "Singapore": "新加坡"
    ]

    /// 2. 统一转换为中文名 (供 UI 列表显示使用)
    /// 逻辑：清理掉 "Province" 等后缀后进行匹配，匹配不到则返回原词
    static func toChinese(_ rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试直接匹配
        if let translated = translationMap[name] {
            return translated
        }
        
        // 模糊处理：去掉常见的行政区划后缀
        let cleanName = name.replacingOccurrences(of: " Province", with: "")
                            .replacingOccurrences(of: " State", with: "")
                            .replacingOccurrences(of: "State of ", with: "")
                            .replacingOccurrences(of: " SAR", with: "")
                            .trimmingCharacters(in: .whitespaces)
        
        return translationMap[cleanName] ?? (cleanName.isEmpty ? "其他" : cleanName)
    }

    /// 3. 转换为 API 搜索用的标识符
    /// 逻辑：将中文转换为该地区在 Radio Browser 数据库中覆盖率最高的英文名
    static func toApiParameter(_ chineseName: String) -> String {
        let apiMap: [String: String] = [
            "广东": "Kwangtung",
            "香港": "香港",
            "台湾": "台湾",
            "澳门": "澳门",
            "北京": "Beijing",
            "上海": "Shanghai",
            "江苏": "Kiangsu",
            "浙江": "Chekiang",
            "湖南": "Hunan",
            "湖北": "Hupei",
            "四川": "Szechuan",
            "山东": "Shantung",
            "天津": "Tientsin",
            "河北": "Hopei",
            "山西": "Shansi",
            "内蒙古": "Inner Mongolia",
            "辽宁": "Liaoning",
            "吉林": "Jilin",
            "黑龙江": "Heilungkiang",
            "安徽": "Anhwei",
            "福建": "Fukien",
            "江西": "Kiangsi",
            "河南": "Honan",
            "广西": "Kwangsi",
            "海南": "Hainan",
            "重庆": "Chungking",
            "贵州": "Kweichow",
            "云南": "Yunnan",
            "西藏": "Tibet",
            "陕西": "Shensi",
            "甘肃": "Kansu",
            "青海": "Tsinghai",
            "宁夏": "Ninghsia",
            "新疆": "Sinkiang",
        
        ]
        // 如果没在字典里，尝试直接返回中文（API 也支持部分中文搜索）
        return apiMap[chineseName] ?? chineseName
    }
}
