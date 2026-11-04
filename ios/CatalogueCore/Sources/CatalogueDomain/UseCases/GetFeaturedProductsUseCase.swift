import Foundation

public struct GetFeaturedProductsUseCase: Sendable {
    private let repository: any ProductRepository

    public init(repository: any ProductRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Product] {
        try await repository.featured()
    }
}
