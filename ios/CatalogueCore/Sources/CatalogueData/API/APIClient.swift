import CatalogueDomain
import Foundation

public struct APIClient: Sendable {
    private let configuration: APIConfiguration
    private let transport: any HTTPTransport

    public init(
        configuration: APIConfiguration,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.configuration = configuration
        self.transport = transport
    }

    func get<Response: Decodable>(
        pathSegments: [String],
        queryItems: [URLQueryItem] = [],
        responseType: Response.Type
    ) async throws -> Response {
        let data = try await perform(
            method: "GET",
            pathSegments: pathSegments,
            queryItems: queryItems,
            body: nil,
            expectedStatusCode: 200
        )
        try Task.checkCancellation()
        let response = try decode(responseType, from: data)
        try Task.checkCancellation()
        return response
    }

    func post<Body: Encodable, Response: Decodable>(
        pathSegments: [String],
        body: Body,
        responseType: Response.Type
    ) async throws -> Response {
        let encodedBody: Data
        do {
            encodedBody = try JSONEncoder().encode(body)
        } catch {
            throw AppError.unexpected
        }

        let data = try await perform(
            method: "POST",
            pathSegments: pathSegments,
            queryItems: [],
            body: encodedBody,
            expectedStatusCode: 202
        )
        try Task.checkCancellation()
        let response = try decode(responseType, from: data)
        try Task.checkCancellation()
        return response
    }

    private func perform(
        method: String,
        pathSegments: [String],
        queryItems: [URLQueryItem],
        body: Data?,
        expectedStatusCode: Int
    ) async throws -> Data {
        do {
            try Task.checkCancellation()
            let request = try makeRequest(
                method: method,
                pathSegments: pathSegments,
                queryItems: queryItems,
                body: body
            )
            let (data, response) = try await transport.send(request)
            try Task.checkCancellation()

            guard response.statusCode == expectedStatusCode else {
                throw HTTPErrorMapper.mapStatus(response.statusCode, data: data)
            }
            return data
        } catch {
            if error is CancellationError || Task.isCancelled {
                throw CancellationError()
            }
            throw HTTPErrorMapper.mapTransportError(error)
        }
    }

    private func makeRequest(
        method: String,
        pathSegments: [String],
        queryItems: [URLQueryItem],
        body: Data?
    ) throws -> URLRequest {
        guard var urlComponents = URLComponents(
            url: configuration.baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw AppError.unexpected
        }

        let encodedSegments = try pathSegments.map(encodePathSegment)
        let baseSegments = urlComponents.percentEncodedPath
            .split(separator: "/")
            .map(String.init)
        urlComponents.percentEncodedPath =
            "/" + (baseSegments + ["api", "v1"] + encodedSegments).joined(separator: "/")
        urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        urlComponents.fragment = nil

        guard let url = urlComponents.url else {
            throw AppError.unexpected
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    private func encodePathSegment(_ segment: String) throws -> String {
        guard let encoded = segment.addingPercentEncoding(
            withAllowedCharacters: Self.pathSegmentAllowedCharacters
        ) else {
            throw AppError.unexpected
        }
        return encoded
    }

    private static let pathSegmentAllowedCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~!$&'()*+,;=:@"
    )

    private func decode<Response: Decodable>(
        _ responseType: Response.Type,
        from data: Data
    ) throws -> Response {
        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            throw AppError.unexpected
        }
    }
}
