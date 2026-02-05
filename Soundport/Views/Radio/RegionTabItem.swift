//
//  RegionTabItem.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/1.
//
import SwiftUI
struct RegionTabItem: View {
    let name: String
    let isSelected: Bool
    
    var body: some View {
        Text(name)
            .font(.system(size: 15, weight: isSelected ? .bold : .regular))
            .foregroundColor(isSelected ? .blue : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            // 选中时左侧加一个小指示条
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 4, height: 20)
                }
            }
            .background(isSelected ? Color.white : Color.clear)
    }
}

