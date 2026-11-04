import Foundation

struct ErrorEnvelopeDTO: Decodable {
    let error: ErrorDTO
}

struct ErrorDTO: Decodable {
    let code: String
    let message: String
    let details: [ErrorDetailDTO]?
}

struct ErrorDetailDTO: Decodable {
    let field: String
    let message: String
}
