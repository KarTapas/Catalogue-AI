import CatalogueDomain
import SwiftUI

enum Route: Hashable {
    case category(String)
    case product(Int)
    case search(String)
}

struct RootView: View {
    @State private var path: [Route]
    @State private var viewModel: HomeViewModel
    private let getCategoryProducts: GetCategoryProductsUseCase

    init(container: AppContainer, initialRoute: Route? = nil) {
        _path = State(initialValue: initialRoute.map { [$0] } ?? [])
        _viewModel = State(
            initialValue: HomeViewModel(
                getFeaturedProducts: container.getFeaturedProducts,
                getCategories: container.getCategories
            )
        )
        getCategoryProducts = container.getCategoryProducts
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(viewModel: viewModel, path: $path)
                .navigationTitle("Catalogue")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(let name):
                        CategoryView(
                            viewModel: CategoryViewModel(
                                categoryName: name,
                                getCategoryProducts: getCategoryProducts
                            ),
                            path: $path
                        )
                    case .product(let id):
                        ProductPlaceholderView(id: id)
                    case .search(let query):
                        SearchPlaceholderView(query: query)
                    }
                }
        }
        .tint(Palette.brand)
    }
}
