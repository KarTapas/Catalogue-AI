import Foundation

public struct SearchProductsUseCase: Sendable {
    private let repository: any ProductRepository

    public init(repository: any ProductRepository) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> [Product] {
        let validatedQuery = try SearchQuery(query)
        return try await repository.search(query: validatedQuery.value)
    }
}
