import Foundation

public struct Enquiry: Equatable, Sendable {
    public let productId: Int
    public let name: String
    public let email: String
    public let phone: String?
    public let message: String

    public init(
        productId: Int,
        name: String,
        email: String,
        phone: String? = nil,
        message: String
    ) {
        self.productId = productId
        self.name = name
        self.email = email
        self.phone = phone
        self.message = message
    }
}
