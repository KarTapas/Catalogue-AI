import Foundation

public struct SearchQuery: Equatable, Sendable {
    public let value: String

    public init(_ rawValue: String) throws {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (2...100).contains(trimmedValue.utf16.count) else {
            throw AppError.validation(
                fields: ["query": "Enter a search query between 2 and 100 characters."]
            )
        }
        value = trimmedValue
    }
}
