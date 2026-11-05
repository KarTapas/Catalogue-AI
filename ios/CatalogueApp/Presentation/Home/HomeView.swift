import CatalogueDomain
import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var path: [Route]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                SearchBar(
                    text: $viewModel.searchText,
                    canSearch: viewModel.canSearch,
                    onSearch: submitSearch
                )

                categoriesSection
                featuredSection
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s16)
        }
        .background(Palette.background)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            guard ProcessInfo.processInfo.environment["CATALOGUE_DISABLE_AUTOMATIC_HOME_LOAD"] != "1" else {
                return
            }
            await viewModel.load()
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            SectionHeader(title: "Categories")

            LoadStateView(
                state: viewModel.categories,
                emptyMessage: "No categories available.",
                isEmpty: { $0.isEmpty },
                onRetry: retry
            ) { categories in
                ScrollView(.horizontal) {
                    HStack(spacing: Spacing.s8) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(category: category) {
                                path.append(.category(category))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            SectionHeader(title: "Featured")

            LoadStateView(
                state: viewModel.featured,
                emptyMessage: "No featured products are available.",
                isEmpty: { $0.isEmpty },
                onRetry: retry
            ) { products in
                ProductGrid(products: products) { product, _ in
                    ProductTile(product: product) {
                        path.append(ProductRoute.route(for: product))
                    }
                }
            }
        }
    }

    private func submitSearch() {
        guard let query = viewModel.submitSearch() else {
            return
        }
        path.append(.search(query))
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }
}
