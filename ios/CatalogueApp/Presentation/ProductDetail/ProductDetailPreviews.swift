import CatalogueDomain
import Foundation
import SwiftUI

private enum ProductDetailPreviewScenario: Sendable {
    case loaded
    case loading
    case error
    case notFound
    case longContent
}

private struct ProductDetailPreviewHost: View {
    @State private var viewModel: ProductDetailViewModel

    init(scenario: ProductDetailPreviewScenario) {
        let repository = ProductDetailPreviewRepository(scenario: scenario)
        _viewModel = State(
            initialValue: ProductDetailViewModel(
                productID: repository.productID,
                getProduct: GetProductUseCase(repository: repository)
            )
        )
    }

    var body: some View {
        NavigationStack {
            ProductDetailView(viewModel: viewModel)
        }
    }
}

private struct ProductDetailPreviewRepository: ProductRepository {
    let scenario: ProductDetailPreviewScenario

    var productID: Int {
        scenario == .notFound ? 9999 : 1
    }

    func featured() async throws -> [Product] {
        [ProductDetailPreviewData.loadedProduct]
    }

    func categories() async throws -> [String] {
        []
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        CategoryProducts(
            category: name,
            topRated: [ProductDetailPreviewData.loadedProduct],
            others: []
        )
    }

    func search(query: String) async throws -> [Product] {
        [ProductDetailPreviewData.loadedProduct]
    }

    func product(id: Int) async throws -> Product {
        switch scenario {
        case .loaded:
            return ProductDetailPreviewData.loadedProduct
        case .loading:
            try await Task.sleep(for: .seconds(3_600))
            return ProductDetailPreviewData.loadedProduct
        case .error:
            throw AppError.unreachable
        case .notFound:
            throw AppError.notFound
        case .longContent:
            return ProductDetailPreviewData.longProduct
        }
    }
}

private enum ProductDetailPreviewData {
    static let loadedProduct = Product(
        id: 1,
        title: "Everyday Canvas Backpack",
        description: "A lightweight backpack with useful storage for daily use.",
        category: "men's clothing",
        price: Money(
            amount: Decimal(string: "109.95", locale: Locale(identifier: "en_US_POSIX"))
                ?? .zero,
            currencyCode: "USD"
        ),
        rating: Rating(rate: 4.7, count: 128)
    )

    static let longProduct = Product(
        id: 2,
        title: "Extra durable travel backpack with adjustable straps and reinforced pockets",
        description: String(
            repeating: "Designed for daily travel, with durable material and roomy compartments. ",
            count: 12
        ),
        category: "men's clothing",
        price: Money(amount: Decimal(149), currencyCode: "USD"),
        rating: Rating(rate: 4.5, count: 84)
    )
}

#Preview("Loaded") {
    ProductDetailPreviewHost(scenario: .loaded)
}

#Preview("Loading") {
    ProductDetailPreviewHost(scenario: .loading)
}

#Preview("Error") {
    ProductDetailPreviewHost(scenario: .error)
}

#Preview("Not found") {
    ProductDetailPreviewHost(scenario: .notFound)
}

#Preview("Large text and long content") {
    ProductDetailPreviewHost(scenario: .longContent)
        .environment(\.dynamicTypeSize, .accessibility5)
}
