import Foundation

public struct GetProductUseCase: Sendable {
    private let repository: any ProductRepository

    public init(repository: any ProductRepository) {
        self.repository = repository
    }

    public func execute(id: Int) async throws -> Product {
        try await repository.product(id: id)
    }
}
