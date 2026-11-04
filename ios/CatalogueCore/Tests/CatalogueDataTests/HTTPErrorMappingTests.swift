import CatalogueData
import CatalogueDomain
import Foundation
import Testing

@Test
func mapsAllRequestedURLFailuresToUnreachable() async throws {
    let codes: [URLError.Code] = [
        .cannotConnectToHost,
        .cannotFindHost,
        .notConnectedToInternet,
        .networkConnectionLost,
        .timedOut,
    ]

    for code in codes {
        let (client, _) = try makeStubbedAPIClient(failure: .url(code))
        let error = await captureDataLayerError {
            try await RemoteProductRepository(apiClient: client).categories()
        }
        #expect((error as? AppError) == .unreachable)
    }
}

@Test
func mapsValidationDetailsUsingTheBackendFieldShape() async throws {
    let body = """
    {
      "error": {
        "code": "VALIDATION_ERROR",
        "message": "Invalid request",
        "details": [
          {"field": "email", "message": "Invalid value"},
          {"field": "message", "message": "Invalid value"}
        ]
      }
    }
    """
    let (client, _) = try makeStubbedAPIClient(responseBody: body, statusCode: 400)
    let error = await captureDataLayerError {
        try await RemoteProductRepository(apiClient: client).categories()
    }

    #expect(
        (error as? AppError) == .validation(
            fields: ["email": "Invalid value", "message": "Invalid value"]
        )
    )
}

@Test
func validationWithoutDetailsUsesOneGenericField() async throws {
    let body = #"{"error":{"code":"VALIDATION_ERROR","message":"Invalid request"}}"#
    let (client, _) = try makeStubbedAPIClient(responseBody: body, statusCode: 400)
    let error = await captureDataLayerError {
        try await RemoteProductRepository(apiClient: client).categories()
    }

    #expect(
        (error as? AppError) == .validation(fields: ["request": "Invalid request"])
    )
}

@Test
func mapsHTTPStatusesAndRejectsUnexpectedOnes() async throws {
    let cases: [(Int, AppError)] = [
        (404, .notFound),
        (429, .rateLimited),
        (502, .serverUnavailable),
        (503, .serverUnavailable),
        (418, .unexpected),
    ]

    for (statusCode, expectedError) in cases {
        let (client, _) = try makeStubbedAPIClient(
            responseBody: #"{"error":{"code":"UPSTREAM_UNAVAILABLE","message":"private body"}}"#,
            statusCode: statusCode
        )
        let error = await captureDataLayerError {
            try await RemoteProductRepository(apiClient: client).categories()
        }
        #expect((error as? AppError) == expectedError)
    }
}

@Test
func malformedJSONAndUnknownValidationCodesMapToUnexpected() async throws {
    let (malformedClient, _) = try makeStubbedAPIClient(responseBody: "{invalid")
    let malformedError = await captureDataLayerError {
        try await RemoteProductRepository(apiClient: malformedClient).categories()
    }
    #expect((malformedError as? AppError) == .unexpected)

    let (wrongCodeClient, _) = try makeStubbedAPIClient(
        responseBody: #"{"error":{"code":"INTERNAL","message":"private details"}}"#,
        statusCode: 400
    )
    let wrongCodeError = await captureDataLayerError {
        try await RemoteProductRepository(apiClient: wrongCodeClient).categories()
    }
    #expect((wrongCodeError as? AppError) == .unexpected)
}

@Test
func cancelledTaskRemainsCancellationError() async throws {
    let (client, _) = try makeStubbedAPIClient()
    let repository = RemoteProductRepository(apiClient: client)
    let task = Task {
        try await repository.categories()
    }
    task.cancel()

    let error = await captureDataLayerError {
        try await task.value
    }
    #expect(error is CancellationError)
}
