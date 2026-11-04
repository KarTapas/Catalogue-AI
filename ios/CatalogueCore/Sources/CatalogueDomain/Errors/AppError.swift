import Foundation

public enum AppError: Error, Equatable, Sendable {
    case unreachable
    case notFound
    case validation(fields: [String: String])
    case rateLimited
    case serverUnavailable
    case unexpected

    public var message: String {
        switch self {
        case .unreachable:
            "Unable to connect. The backend may not be running."
        case .notFound:
            "The requested item could not be found."
        case .validation:
            "Please check the information you entered."
        case .rateLimited:
            "Too many requests. Please wait a moment before trying again."
        case .serverUnavailable:
            "The service is temporarily unavailable. Please try again later."
        case .unexpected:
            "Something went wrong. Please try again."
        }
    }
}
