import Foundation

public struct EnquiryReceipt: Equatable, Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}
