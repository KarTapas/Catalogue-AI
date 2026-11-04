import Foundation

public protocol ProductRepository: Sendable {
    func featured() async throws -> [Product]
    func categories() async throws -> [String]
    func categoryProducts(name: String) async throws -> CategoryProducts
    func search(query: String) async throws -> [Product]
    func product(id: Int) async throws -> Product
}
