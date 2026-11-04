import CatalogueDomain
import SwiftUI

private enum CategoryPreviewScenario: Sendable {
    case loaded
    case loadedWithoutOthers
    case loading
    case error
    case empty
}

private struct CategoryPreviewHost: View {
    @State private var viewModel: CategoryViewModel
    @State private var path: [Route] = []
    private let repository: CategoryPreviewRepository

    init(scenario: CategoryPreviewScenario) {
        let repository = CategoryPreviewRepository(scenario: scenario)
        self.repository = repository
        _viewModel = State(
            initialValue: CategoryViewModel(
                categoryName: "men's clothing",
                getCategoryProducts: GetCategoryProductsUseCase(repository: repository)
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            CategoryView(viewModel: viewModel, path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(let category):
                        Text("Category: \(category)")
                    case .product(let id):
                        ProductPlaceholderView(id: id)
                    case .search(let query):
                        SearchResultsView(
                            viewModel: SearchResultsViewModel(
                                initialQuery: query,
                                searchProducts: SearchProductsUseCase(repository: repository)
                            ),
                            path: $path
                        )
                    }
                }
        }
    }
}

private struct CategoryPreviewRepository: ProductRepository {
    let scenario: CategoryPreviewScenario

    func featured() async throws -> [Product] {
        []
    }

    func categories() async throws -> [String] {
        []
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        switch scenario {
        case .loaded:
            return CategoryPreviewData.products
        case .loadedWithoutOthers:
            return CategoryPreviewData.productsWithoutOthers
        case .loading:
            try await Task.sleep(for: .seconds(3_600))
            return CategoryPreviewData.products
        case .error:
            throw AppError.unreachable
        case .empty:
            return CategoryProducts(category: name, topRated: [], others: [])
        }
    }

    func search(query: String) async throws -> [Product] {
        []
    }

    func product(id: Int) async throws -> Product {
        guard let product = CategoryPreviewData.products.topRated.first(where: { $0.id == id })
            ?? CategoryPreviewData.products.others.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return product
    }
}

private enum CategoryPreviewData {
    static let products = CategoryProducts(
        category: "men's clothing",
        topRated: (1...3).map(product),
        others: (4...5).map(product)
    )
    static let productsWithoutOthers = CategoryProducts(
        category: "men's clothing",
        topRated: (1...3).map(product),
        others: []
    )

    private static func product(_ id: Int) -> Product {
        Product(
            id: id,
            title: "Everyday Shirt \(id)",
            description: "A comfortable everyday shirt.",
            category: "men's clothing",
            price: Money(amount: Decimal(id * 25), currencyCode: "USD"),
            rating: Rating(rate: 4.7, count: 40 + id)
        )
    }
}

#Preview("Loaded · 3+2") {
    CategoryPreviewHost(scenario: .loaded)
}

#Preview("Loaded · 3+0") {
    CategoryPreviewHost(scenario: .loadedWithoutOthers)
}

#Preview("Loading") {
    CategoryPreviewHost(scenario: .loading)
}

#Preview("Error") {
    CategoryPreviewHost(scenario: .error)
}

#Preview("Empty") {
    CategoryPreviewHost(scenario: .empty)
}
