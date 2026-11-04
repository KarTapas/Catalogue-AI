import CatalogueData
import CatalogueDomain
import Foundation
import Testing

@Test(
    .enabled(
        if: ProcessInfo.processInfo.environment["CATALOGUE_LIVE_API_URL"] != nil,
        "Set CATALOGUE_LIVE_API_URL to run the live backend contract test."
    )
)
func liveBackendContract() async throws {
    let baseURLString = try #require(
        ProcessInfo.processInfo.environment["CATALOGUE_LIVE_API_URL"]
    )
    let baseURL = try #require(URL(string: baseURLString))
    let repository = RemoteProductRepository(
        apiClient: APIClient(configuration: APIConfiguration(baseURL: baseURL))
    )

    let featured = try await repository.featured()
    let categories = try await repository.categories()
    let category = try await repository.categoryProducts(name: "men's clothing")
    let searchResults = try await repository.search(query: "jacket")
    let product = try await repository.product(id: 1)
    let missingProductError = await captureDataLayerError {
        try await repository.product(id: 9999)
    }

    #expect(featured.count == 5)
    #expect(categories.count == 4)
    #expect(category.topRated.count == 3)
    #expect(!searchResults.isEmpty)
    #expect(product.id == 1)
    #expect((missingProductError as? AppError) == .notFound)
}
