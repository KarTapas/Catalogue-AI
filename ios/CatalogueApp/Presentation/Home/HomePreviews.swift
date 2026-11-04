import CatalogueDomain
import SwiftUI

private enum HomePreviewScenario: Sendable {
    case loaded
    case loading
    case featuredError
    case categoriesError
    case empty
}

private struct HomePreviewHost: View {
    @State private var viewModel: HomeViewModel
    @State private var path: [Route] = []

    init(scenario: HomePreviewScenario) {
        let repository = HomePreviewProductRepository(scenario: scenario)
        _viewModel = State(
            initialValue: HomeViewModel(
                getFeaturedProducts: GetFeaturedProductsUseCase(repository: repository),
                getCategories: GetCategoriesUseCase(repository: repository)
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(viewModel: viewModel, path: $path)
                .navigationTitle("Catalogue")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(let category):
                        CategoryPlaceholderView(category: category)
                    case .product(let id):
                        ProductPlaceholderView(id: id)
                    case .search(let query):
                        SearchPlaceholderView(query: query)
                    }
                }
        }
        .environment(\.dynamicTypeSize, .accessibility5)
    }
}

private struct HomePreviewProductRepository: ProductRepository {
    let scenario: HomePreviewScenario

    func featured() async throws -> [Product] {
        switch scenario {
        case .featuredError:
            throw AppError.unreachable
        case .loading:
            try await Task.sleep(for: .seconds(3_600))
            return HomePreviewProducts.products
        case .empty:
            return []
        case .loaded, .categoriesError:
            return HomePreviewProducts.products
        }
    }

    func categories() async throws -> [String] {
        switch scenario {
        case .categoriesError:
            throw AppError.unreachable
        case .loading:
            try await Task.sleep(for: .seconds(3_600))
            return ["electronics", "men's clothing", "women's clothing"]
        case .empty:
            return []
        case .loaded, .featuredError:
            return ["electronics", "men's clothing", "women's clothing"]
        }
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        let products = try await featured()
        return CategoryProducts(
            category: name,
            topRated: Array(products.prefix(3)),
            others: Array(products.dropFirst(3))
        )
    }

    func search(query: String) async throws -> [Product] {
        try await featured()
    }

    func product(id: Int) async throws -> Product {
        guard let product = HomePreviewProducts.products.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return product
    }
}

private enum HomePreviewProducts {
    static let products = (1...5).map { id in
        Product(
            id: id,
            title: "Everyday Backpack \(id)",
            description: "A lightweight bag for daily use.",
            category: "accessories",
            price: Money(amount: Decimal(id * 25), currencyCode: "USD"),
            rating: Rating(rate: 4.7, count: 40 + id)
        )
    }
}

#Preview("Loaded · Accessibility 5") {
    HomePreviewHost(scenario: .loaded)
}

#Preview("Loading") {
    HomePreviewHost(scenario: .loading)
}

#Preview("Featured error") {
    HomePreviewHost(scenario: .featuredError)
}

#Preview("Categories error") {
    HomePreviewHost(scenario: .categoriesError)
}

#Preview("Empty") {
    HomePreviewHost(scenario: .empty)
}
