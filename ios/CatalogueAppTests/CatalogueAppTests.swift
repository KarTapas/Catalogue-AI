import CatalogueDomain
import Foundation
import Testing
@testable import CatalogueApp

@Test
func appConfigAcceptsAbsoluteLocalHTTPURL() throws {
    let configuration = try AppConfig(
        infoDictionary: ["APIBaseURL": "http://localhost:3000"]
    )

    #expect(configuration.apiBaseURL.absoluteString == "http://localhost:3000")
}

@Test(arguments: ["", "not a url", "/api/v1", "ftp://localhost:3000"])
func appConfigRejectsInvalidURLs(_ value: String) {
    do {
        _ = try AppConfig(infoDictionary: ["APIBaseURL": value])
        Issue.record("Expected an invalid API base URL to be rejected.")
    } catch let error as AppConfigError {
        #expect(error == .invalidAPIBaseURL)
    } catch {
        Issue.record("Unexpected configuration error: \(error.localizedDescription)")
    }
}

@Test
func loadStateExposesLoadingAndLoadedValues() {
    let idle: LoadState<Int> = .idle
    let loading: LoadState<Int> = .loading
    let loaded: LoadState<Int> = .loaded(42)
    let failed: LoadState<Int> = .failed(.unreachable)

    #expect(!idle.isLoading)
    #expect(idle.value == nil)
    #expect(loading.isLoading)
    #expect(loading.value == nil)
    #expect(loaded.value == 42)
    #expect(failed.value == nil)
    #expect(loaded == .loaded(42))
    #expect(failed == .failed(.unreachable))
}

@Test
func appContainerUsesInjectedFakeRepositories() async throws {
    let product = makeSampleProduct()
    let receipt = EnquiryReceipt(id: "test-receipt")
    let container = AppContainer(
        productRepository: FakeProductRepository(product: product),
        enquiryRepository: FakeEnquiryRepository(receipt: receipt)
    )

    #expect(try await container.getFeaturedProducts.execute() == [product])
    #expect(try await container.getCategories.execute() == ["Apparel"])
    #expect(
        try await container.getCategoryProducts.execute(name: "Apparel")
            == CategoryProducts(category: "Apparel", topRated: [product], others: [])
    )
    #expect(try await container.searchProducts.execute(query: "backpack") == [product])
    #expect(try await container.getProduct.execute(id: product.id) == product)

    let enquiry = Enquiry(
        productId: product.id,
        name: "Alex",
        email: "alex@example.test",
        message: "I have a question."
    )
    #expect(try await container.submitEnquiry.execute(enquiry) == receipt)
}

@Test
func appInfoPlistUsesConfiguredURLAndLocalhostOnlyATSException() throws {
    let infoDictionary = try #require(Bundle.main.infoDictionary)
    let apiBaseURL = try #require(infoDictionary["APIBaseURL"] as? String)
    #expect(apiBaseURL == "http://localhost:3000")

    let transportSecurity = try #require(
        infoDictionary["NSAppTransportSecurity"] as? [String: Any]
    )
    #expect(transportSecurity["NSAllowsArbitraryLoads"] as? Bool != true)
    #expect(transportSecurity["NSAllowsLocalNetworking"] == nil)

    let exceptionDomains = try #require(
        transportSecurity["NSExceptionDomains"] as? [String: Any]
    )
    #expect(Set(exceptionDomains.keys) == Set(["localhost"]))

    let localhost = try #require(exceptionDomains["localhost"] as? [String: Any])
    #expect(localhost["NSExceptionAllowsInsecureHTTPLoads"] as? Bool == true)
    #expect(localhost["NSIncludesSubdomains"] == nil)
}

private func makeSampleProduct() -> Product {
    Product(
        id: 7,
        title: "Everyday Backpack",
        description: "A useful bag.",
        category: "Apparel",
        price: Money(
            amount: Decimal(string: "109.95") ?? .zero,
            currencyCode: "USD"
        ),
        rating: Rating(rate: 4.5, count: 40)
    )
}

private struct FakeProductRepository: ProductRepository {
    let product: Product

    func featured() async throws -> [Product] {
        [product]
    }

    func categories() async throws -> [String] {
        ["Apparel"]
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        CategoryProducts(category: name, topRated: [product], others: [])
    }

    func search(query: String) async throws -> [Product] {
        [product]
    }

    func product(id: Int) async throws -> Product {
        product
    }
}

private struct FakeEnquiryRepository: EnquiryRepository {
    let receipt: EnquiryReceipt

    func submit(_ enquiry: Enquiry) async throws -> EnquiryReceipt {
        receipt
    }
}
