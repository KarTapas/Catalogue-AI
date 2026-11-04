import Foundation

public struct Product: Equatable, Sendable {
    public let id: Int
    public let title: String
    public let description: String
    public let category: String
    public let price: Money
    public let imageURL: URL?
    public let rating: Rating

    public init(
        id: Int,
        title: String,
        description: String,
        category: String,
        price: Money,
        imageURL: URL? = nil,
        rating: Rating
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.imageURL = imageURL
        self.rating = rating
    }
}
