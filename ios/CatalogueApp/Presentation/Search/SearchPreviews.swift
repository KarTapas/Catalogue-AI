import CatalogueDomain
import SwiftUI

private struct SearchPreviewHost: View {
    @State private var viewModel: SearchResultsViewModel
    @State private var path: [Route] = []

    init(query: String, repository: SearchPreviewRepository) {
        _viewModel = State(
            initialValue: SearchResultsViewModel(
                initialQuery: query,
                searchProducts: SearchProductsUseCase(repository: repository)
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            SearchResultsView(viewModel: viewModel, path: $path)
        }
    }
}

private struct SearchPreviewRepository: ProductRepository {
    let products: [Product]
    let error: AppError?
    let suspends: Bool

    init(products: [Product], error: AppError? = nil, suspends: Bool = false) {
        self.products = products
        self.error = error
        self.suspends = suspends
    }

    func featured() async throws -> [Product] {
        products
    }

    func categories() async throws -> [String] {
        []
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        CategoryProducts(category: name, topRated: products, others: [])
    }

    func search(query: String) async throws -> [Product] {
        if suspends {
            try await Task.sleep(for: .seconds(86_400))
        }
        if let error {
            throw error
        }
        return products
    }

    func product(id: Int) async throws -> Product {
        guard let product = products.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return product
    }
}

private enum SearchPreviewData {
    static let jacketProducts = [
        product(id: 1, title: "Lightweight Jacket"),
        product(id: 2, title: "Weatherproof Jacket"),
        product(id: 3, title: "Everyday Jacket")
    ]

    static let singleProduct = product(id: 4, title: "Canvas Backpack")

    private static func product(id: Int, title: String) -> Product {
        Product(
            id: id,
            title: title,
            description: "A sample catalogue product.",
            category: "Accessories",
            price: Money(amount: Decimal(id + 39), currencyCode: "USD"),
            rating: Rating(rate: 4.7, count: 128)
        )
    }
}

#Preview("Results") {
    SearchPreviewHost(
        query: "jacket",
        repository: SearchPreviewRepository(products: SearchPreviewData.jacketProducts)
    )
}

#Preview("One result") {
    SearchPreviewHost(
        query: "backpack",
        repository: SearchPreviewRepository(products: [SearchPreviewData.singleProduct])
    )
}

#Preview("No results") {
    SearchPreviewHost(
        query: "zzzzqq",
        repository: SearchPreviewRepository(products: [])
    )
}

#Preview("Loading") {
    SearchPreviewHost(
        query: "jacket",
        repository: SearchPreviewRepository(products: [], suspends: true)
    )
}

#Preview("Error") {
    SearchPreviewHost(
        query: "jacket",
        repository: SearchPreviewRepository(products: [], error: .unreachable)
    )
}

#Preview("Invalid text") {
    SearchPreviewHost(
        query: "a",
        repository: SearchPreviewRepository(products: [])
    )
}
