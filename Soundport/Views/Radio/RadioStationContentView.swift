//
//  RadioStationContentView.swift
//  Soundport
//
//  Created by Codex on 2026/3/2.
//

import SwiftUI

struct RadioStationContentView: View {
    @ObservedObject var viewModel: RadioViewModel
    @Binding var showSearchSheet: Bool
    let miniPlayerHeight: CGFloat
    let onStationTap: (Station) -> Void

    var body: some View {
        VStack(spacing: 0) {
            RadioSearchHeaderView(showSearchSheet: $showSearchSheet)

            if viewModel.stations.isEmpty && !viewModel.isLoading {
                RadioEmptyStateView(selectedCategory: viewModel.selectedCategory)
            } else {
                List {
                    Section(header: Text(categoryTitle).font(.subheadline)) {
                        ForEach(viewModel.stations) { station in
                            StationRow(station: station)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onStationTap(station)
                                }
                        }
                        // ✅ 仅在收藏分类启用拖拽排序
                        .onMove(perform: { source, destination in
                            if viewModel.selectedCategory == .favorites {
                                FavoritesManager.shared.moveStation(from: source, to: destination)
                            }
                        })
                    }

                    if !viewModel.stations.isEmpty && viewModel.selectedCategory != .favorites {
                        RadioPaginationFooterView(
                            isFetchingMore: viewModel.isFetchingMore,
                            loadError: viewModel.loadError,
                            canLoadMore: viewModel.canLoadMore,
                            onRetry: {
                                viewModel.loadError = false
                                Task { await viewModel.loadData(isNextPage: true) }
                            },
                            onLoadMore: {
                                Task { await viewModel.loadData(isNextPage: true) }
                            }
                        )
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 10)
                    }

                    Color.clear
                        .frame(height: miniPlayerHeight)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
    }

    private var categoryTitle: String {
        if viewModel.selectedCategory == .region {
            return viewModel.selectedProvince
        }
        if viewModel.selectedCategory == .country {
            return viewModel.selectedCountry
        }
        return viewModel.selectedCategory.rawValue
    }
}
