import Foundation

public struct GetCategoriesUseCase: Sendable {
    private let repository: any ProductRepository

    public init(repository: any ProductRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [String] {
        try await repository.categories()
    }
}
