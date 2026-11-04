import CatalogueData
import CatalogueDomain
import Foundation
import Testing

@Test
func featuredProductsDecodeAndUseTheDocumentedRequest() async throws {
    let featuredJSON = APIJSONFixtures.array([
        APIJSONFixtures.product(
            id: 12,
            title: "WD 4TB Gaming Drive",
            category: "electronics",
            amount: "114.99",
            rate: 4.8,
            ratingCount: 400
        ),
        APIJSONFixtures.product(
            id: 11,
            title: "Silicon Power 256GB SSD",
            category: "electronics",
            amount: "109.99",
            rate: 4.8,
            ratingCount: 319
        ),
    ])
    let (client, transport) = try makeStubbedAPIClient(responseBody: featuredJSON)
    let repository = RemoteProductRepository(apiClient: client)

    let products = try await repository.featured()

    #expect(products.map(\.id) == [12, 11])
    #expect(products.first?.title == "WD 4TB Gaming Drive")
    #expect(products.first?.price.currencyCode == "USD")
    try await expectRequest(
        from: transport,
        url: "https://api.example.test/api/v1/products/featured",
        method: "GET"
    )
}

@Test
func categoriesDecodeAndUseTheDocumentedRequest() async throws {
    let (client, transport) = try makeStubbedAPIClient(
        responseBody: #"["electronics","jewelery","men's clothing","women's clothing"]"#
    )
    let repository = RemoteProductRepository(apiClient: client)

    let categories = try await repository.categories()

    #expect(categories == ["electronics", "jewelery", "men's clothing", "women's clothing"])
    try await expectRequest(
        from: transport,
        url: "https://api.example.test/api/v1/categories",
        method: "GET"
    )
}

@Test
func categoryProductsDecodeTheSplitAndEncodeNamesAsSinglePathSegments() async throws {
    let categoryJSON = APIJSONFixtures.categoryProducts(
        topRated: [APIJSONFixtures.product()],
        others: [APIJSONFixtures.product(id: 3, title: "Mens Cotton Jacket", amount: "55.99")]
    )
    let (client, transport) = try makeStubbedAPIClient(responseBody: categoryJSON)
    let repository = RemoteProductRepository(apiClient: client)

    let result = try await repository.categoryProducts(name: "men's clothing")

    #expect(result.category == "men's clothing")
    #expect(result.topRated.map(\.id) == [1])
    #expect(result.others.map(\.id) == [3])
    try await expectRequest(
        from: transport,
        url: "https://api.example.test/api/v1/categories/men's%20clothing/products",
        method: "GET"
    )

    let (slashClient, slashTransport) = try makeStubbedAPIClient(
        responseBody: APIJSONFixtures.categoryProducts(
            category: "home/kitchen",
            topRated: [],
            others: []
        )
    )
    _ = try await RemoteProductRepository(apiClient: slashClient)
        .categoryProducts(name: "home/kitchen")
    try await expectRequest(
        from: slashTransport,
        url: "https://api.example.test/api/v1/categories/home%2Fkitchen/products",
        method: "GET"
    )
}

@Test
func searchDecodesProductsAndEncodesTheQueryWithURLQueryItems() async throws {
    let (client, transport) = try makeStubbedAPIClient(
        responseBody: APIJSONFixtures.array([APIJSONFixtures.product()])
    )
    let repository = RemoteProductRepository(apiClient: client)

    let products = try await repository.search(query: "winter jacket & scarf")

    #expect(products.count == 1)
    #expect(products[0].id == 1)
    try await expectRequest(
        from: transport,
        url: "https://api.example.test/api/v1/products/search?q=winter%20jacket%20%26%20scarf",
        method: "GET"
    )
}

@Test
func productDecodesDecimalStringAndBuildsTheIdRequest() async throws {
    let (client, transport) = try makeStubbedAPIClient(
        responseBody: APIJSONFixtures.product()
    )
    let repository = RemoteProductRepository(apiClient: client)

    let product = try await repository.product(id: 1)
    let expectedAmount = try #require(
        Decimal(string: "109.95", locale: Locale(identifier: "en_US_POSIX"))
    )
    let expectedImageURL = try #require(URL(string: APIJSONFixtures.documentedProductImage))

    #expect(product.id == 1)
    #expect(product.title == APIJSONFixtures.documentedProductTitle)
    #expect(product.category == "men's clothing")
    #expect(product.price.amount == expectedAmount)
    #expect(NSDecimalNumber(decimal: product.price.amount).stringValue == "109.95")
    #expect(product.price.currencyCode == "USD")
    #expect(product.imageURL == expectedImageURL)
    #expect(product.rating == Rating(rate: 3.9, count: 120))
    try await expectRequest(
        from: transport,
        url: "https://api.example.test/api/v1/products/1",
        method: "GET"
    )
}

@Test
func unparseablePriceFailsMappingAndInvalidImageURLMapsToNil() async throws {
    let (badPriceClient, _) = try makeStubbedAPIClient(
        responseBody: APIJSONFixtures.product(amount: "not-a-decimal")
    )
    let badPriceError = await captureDataLayerError {
        try await RemoteProductRepository(apiClient: badPriceClient).product(id: 1)
    }
    #expect((badPriceError as? AppError) == .unexpected)

    let (invalidImageClient, _) = try makeStubbedAPIClient(
        responseBody: APIJSONFixtures.product(imageURL: "not a URL")
    )
    let product = try await RemoteProductRepository(apiClient: invalidImageClient)
        .product(id: 1)
    #expect(product.imageURL == nil)
}
