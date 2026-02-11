//
//  ProvincePickerView.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/10.
//

//let allProvinces = ["广东", "香港", "台湾", "澳门", "北京", "上海", "江苏", "浙江", "湖南", "湖北", "四川", "山东","天津","河北","山西","内蒙古","辽宁","吉林","黑龙江","安徽","福建","江西","河南","广西","海南","重庆","贵州","云南","西藏","陕西","甘肃","青海","宁夏","新疆"]

import SwiftUI
import Combine

struct ProvincePickerView: View {
    @ObservedObject var viewModel: RadioViewModel
    @Environment(\.dismiss) var dismiss
    
    // 热门及常用省份列表
    let provinces = [
        "广东", "香港", "台湾", "澳门", "北京", "上海", "江苏", "浙江", "湖南", "湖北", "四川",   "山东","天津","河北","山西","内蒙古","辽宁","吉林","黑龙江","安徽","福建","江西","河南","广西","海南","重庆","贵州","云南","西藏","陕西","甘肃","青海","宁夏","新疆"
    ]
    
    // 定义网格列数：一行 3 个
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(provinces, id: \.self) { province in
                        Button(action: {
                            Task {
                                await viewModel.changeProvince(to: province)
                                dismiss() // 点选后自动关闭
                            }
                        }) {
                            Text(province)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(viewModel.selectedProvince == province ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(viewModel.selectedProvince == province ? Color.blue : Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择地区")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large]) // 支持半屏和全屏切换
    }
}
