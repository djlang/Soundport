//
//  RadioCategorySidebarView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI

struct RadioCategorySidebarView: View {
    let selectedCategory: RadioCategory
    let selectedProvince: String
    let selectedCountry: String
    let miniPlayerHeight: CGFloat
    let onCategoryTap: (RadioCategory) -> Void
    let onRepeatRegionTap: () -> Void
    let onRepeatCountryTap: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(RadioCategory.allCases) { category in
                    let isSelected = selectedCategory == category

                    VStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .blue : .gray)

                        Text(displayName(for: category))
                            .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? .blue : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 75)
                    .background(isSelected ? Color(UIColor.systemBackground) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if category == .region && selectedCategory == .region {
                            onRepeatRegionTap()
                        } else if category == .country && selectedCategory == .country {
                            onRepeatCountryTap()
                        } else {
                            onCategoryTap(category)
                        }
                    }

                    Divider()
                        .padding(.horizontal, 10)
                        .opacity(0.3)
                }
            }
            .padding(.top, 10)

            Spacer(minLength: miniPlayerHeight)
        }
        .frame(width: 85)
        .background(Color(UIColor.systemGray6).opacity(0.8))
        .overlay(Divider(), alignment: .trailing)
    }

    private func displayName(for category: RadioCategory) -> String {
        if category == .region {
            return selectedProvince
        }
        if category == .country {
            return selectedCountry
        }
        return category.rawValue
    }
}
