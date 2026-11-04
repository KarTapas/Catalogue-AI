import SwiftUI

struct SearchResultsView: View {
    @State private var viewModel: SearchResultsViewModel
    @Binding private var path: [Route]

    init(viewModel: SearchResultsViewModel, path: Binding<[Route]>) {
        _viewModel = State(initialValue: viewModel)
        _path = path
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                SearchBar(
                    text: $viewModel.searchText,
                    canSearch: viewModel.canSearch,
                    onSearch: submitSearch,
                    validationMessage: viewModel.validationMessage
                )

                if let summary = viewModel.resultSummary {
                    Text(verbatim: summary)
                        .font(Typography.body)
                        .foregroundStyle(Palette.textSecondary)
                        .accessibilityLabel(Text(verbatim: summary))
                        .accessibilityAddTraits(.updatesFrequently)
                }

                LoadStateView(
                    state: viewModel.results,
                    emptyMessage: viewModel.emptyMessage,
                    isEmpty: { $0.isEmpty },
                    onRetry: retry,
                    errorMessage: { SearchResultsText.errorMessage(for: $0) }
                ) { products in
                    ProductGrid(products: products) { product, _ in
                        ProductTile(product: product) {
                            path.append(ProductRoute.route(for: product))
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s16)
        }
        .background(Palette.background)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.start()
        }
    }

    private func submitSearch() {
        Task {
            await viewModel.search()
        }
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }
}
