//
//  CountryPickerView.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/12.

import SwiftUI
import Combine

struct CountryPickerView: View {
    @ObservedObject var viewModel: RadioViewModel
    @Environment(\.dismiss) var dismiss
    
    let countryName = ["美国","英国","泰国","韩国","阿根廷","澳大利亚","巴西","加拿大","智利","芬兰","日本","肯尼亚", "马来西亚","波兰", "俄罗斯","新加坡","瑞士","乌克兰","希腊","丹麦", "法国","以色列", "墨西哥", "新西兰", "越南", "委内瑞拉", "乌拉圭" , "乌干达", "土耳其", "突尼斯","叙利亚","瑞典", "斯里兰卡", "西班牙"	]
    
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
                    ForEach(countryName, id: \.self) { cy in
                        Button(action: {
                            Task {
                                await viewModel.changeCountry(to: cy)
                                dismiss() // 点选后自动关闭
                            }
                        }) {
                            Text(cy)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(viewModel.selectedCountry == cy ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(viewModel.selectedCountry == cy ? Color.blue : Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择国家")
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
