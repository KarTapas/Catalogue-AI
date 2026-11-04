import Foundation

enum AppConfigError: LocalizedError, Equatable {
    case missingAPIBaseURL
    case invalidAPIBaseURL

    var errorDescription: String? {
        switch self {
        case .missingAPIBaseURL:
            "The API URL is not configured."
        case .invalidAPIBaseURL:
            "The API URL must be an absolute HTTP or HTTPS address."
        }
    }
}

struct AppConfig: Equatable {
    let apiBaseURL: URL

    init(bundle: Bundle = .main) throws {
        self = try Self(infoDictionary: bundle.infoDictionary ?? [:])
    }

    init(infoDictionary: [String: Any]) throws {
        guard let value = infoDictionary["APIBaseURL"] as? String else {
            throw AppConfigError.missingAPIBaseURL
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty,
              let components = URLComponents(string: trimmedValue),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty,
              let url = components.url else {
            throw AppConfigError.invalidAPIBaseURL
        }

        apiBaseURL = url
    }
}
