import CatalogueDomain
import Foundation

public struct RemoteProductRepository: ProductRepository, Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func featured() async throws -> [Product] {
        let products = try await apiClient.get(
            pathSegments: ["products", "featured"],
            responseType: [ProductDTO].self
        )
        return try products.map(DTOMapper.product)
    }

    public func categories() async throws -> [String] {
        try await apiClient.get(
            pathSegments: ["categories"],
            responseType: [String].self
        )
    }

    public func categoryProducts(name: String) async throws -> CategoryProducts {
        let result = try await apiClient.get(
            pathSegments: ["categories", name, "products"],
            responseType: CategoryProductsDTO.self
        )
        return try DTOMapper.categoryProducts(result)
    }

    public func search(query: String) async throws -> [Product] {
        let products = try await apiClient.get(
            pathSegments: ["products", "search"],
            queryItems: [URLQueryItem(name: "q", value: query)],
            responseType: [ProductDTO].self
        )
        return try products.map(DTOMapper.product)
    }

    public func product(id: Int) async throws -> Product {
        let result = try await apiClient.get(
            pathSegments: ["products", String(id)],
            responseType: ProductDTO.self
        )
        return try DTOMapper.product(result)
    }
}
