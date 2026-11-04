import Foundation

public struct CategoryProducts: Equatable, Sendable {
    public let category: String
    public let topRated: [Product]
    public let others: [Product]

    public init(category: String, topRated: [Product], others: [Product]) {
        self.category = category
        self.topRated = topRated
        self.others = others
    }
}
