import CatalogueDomain
import Foundation

enum HTTPErrorMapper {
    static func mapTransportError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        guard let urlError = error as? URLError else {
            return .unexpected
        }

        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost, .notConnectedToInternet,
             .networkConnectionLost, .timedOut:
            return .unreachable
        default:
            return .unexpected
        }
    }

    static func mapStatus(_ statusCode: Int, data: Data) -> AppError {
        switch statusCode {
        case 400:
            mapValidationError(data)
        case 404:
            .notFound
        case 429:
            .rateLimited
        case 500...599:
            .serverUnavailable
        default:
            .unexpected
        }
    }

    private static func mapValidationError(_ data: Data) -> AppError {
        let envelope: ErrorEnvelopeDTO
        do {
            envelope = try JSONDecoder().decode(ErrorEnvelopeDTO.self, from: data)
        } catch {
            return .unexpected
        }

        guard envelope.error.code == "VALIDATION_ERROR" else {
            return .unexpected
        }

        let fields = (envelope.error.details ?? []).reduce(into: [String: String]()) {
            result, detail in
            result[detail.field] = detail.message
        }
        return .validation(
            fields: fields.isEmpty ? ["request": "Invalid request"] : fields
        )
    }
}
