import CatalogueDomain
import SwiftUI

struct CategoryView: View {
    @State private var viewModel: CategoryViewModel
    @Binding private var path: [Route]

    init(viewModel: CategoryViewModel, path: Binding<[Route]>) {
        _viewModel = State(initialValue: viewModel)
        _path = path
    }

    var body: some View {
        ScrollView {
            LoadStateView(
                state: viewModel.content,
                emptyMessage: "No products in this category.",
                isEmpty: CategoryDisplay.isEmpty,
                onRetry: retry,
                errorMessage: { CategoryDisplay.errorMessage(for: $0) }
            ) { products in
                VStack(alignment: .leading, spacing: Spacing.s24) {
                    productSection(
                        title: "Top rated",
                        products: products.topRated,
                        showsRank: true
                    )

                    if !products.others.isEmpty {
                        productSection(
                            title: "More in \(viewModel.displayTitle)",
                            products: products.others,
                            showsRank: false
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s16)
        }
        .background(Palette.background)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.load()
        }
        .navigationTitle(viewModel.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func productSection(
        title: String,
        products: [Product],
        showsRank: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            SectionHeader(title: title)

            ProductGrid(products: products) { product, position in
                ProductTile(
                    product: product,
                    action: { path.append(ProductRoute.route(for: product)) },
                    rank: showsRank ? position : nil
                )
            }
        }
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }
}
