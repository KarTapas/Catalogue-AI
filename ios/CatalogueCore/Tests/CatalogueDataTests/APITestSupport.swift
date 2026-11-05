import CatalogueData
import Foundation
import Testing

enum StubTransportFailure: Sendable {
    case url(URLError.Code)
    case cancellation
    case unexpected
}

private struct StubTransportError: Error, Sendable {}

private enum StubSetupError: Error {
    case invalidURL
    case missingRequest
}

actor StubHTTPTransport: HTTPTransport {
    private let data: Data
    private let response: HTTPURLResponse
    private let failure: StubTransportFailure?
    private var requests: [URLRequest] = []

    init(
        data: Data,
        response: HTTPURLResponse,
        failure: StubTransportFailure? = nil
    ) {
        self.data = data
        self.response = response
        self.failure = failure
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        try Task.checkCancellation()

        if let failure {
            switch failure {
            case .url(let code):
                throw URLError(code)
            case .cancellation:
                throw CancellationError()
            case .unexpected:
                throw StubTransportError()
            }
        }

        return (data, response)
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

func makeStubbedAPIClient(
    responseBody: String = "[]",
    statusCode: Int = 200,
    failure: StubTransportFailure? = nil
) throws -> (client: APIClient, transport: StubHTTPTransport) {
    guard
        let baseURL = URL(string: "https://api.example.test"),
        let responseURL = URL(string: "https://api.example.test"),
        let response = HTTPURLResponse(
            url: responseURL,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    else {
        throw StubSetupError.invalidURL
    }

    let transport = StubHTTPTransport(
        data: Data(responseBody.utf8),
        response: response,
        failure: failure
    )
    return (
        APIClient(
            configuration: APIConfiguration(baseURL: baseURL),
            transport: transport
        ),
        transport
    )
}

func capturedRequest(from transport: StubHTTPTransport) async throws -> URLRequest {
    guard let request = await transport.recordedRequests().first else {
        throw StubSetupError.missingRequest
    }
    return request
}

func expectRequest(
    from transport: StubHTTPTransport,
    url expectedURL: String,
    method expectedMethod: String
) async throws {
    let request = try await capturedRequest(from: transport)
    #expect(request.url?.absoluteString == expectedURL)
    #expect(request.httpMethod == expectedMethod)
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
}

func captureDataLayerError<T>(
    from operation: () async throws -> T
) async -> (any Error)? {
    do {
        _ = try await operation()
        return nil
    } catch {
        return error
    }
}
