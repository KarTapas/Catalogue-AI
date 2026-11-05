import Foundation

public struct GetCategoryProductsUseCase: Sendable {
    private let repository: any ProductRepository

    public init(repository: any ProductRepository) {
        self.repository = repository
    }

    public func execute(name: String) async throws -> CategoryProducts {
        try await repository.categoryProducts(name: name)
    }
}
