import Foundation

public struct Rating: Equatable, Sendable {
    public let rate: Double
    public let count: Int

    public init(rate: Double, count: Int) {
        self.rate = rate
        self.count = count
    }
}
