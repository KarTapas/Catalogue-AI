import CatalogueData
import CatalogueDomain
import Foundation
import Testing

@Test
func enquiryPostsTheExpectedJSONAndReturnsTheReceipt() async throws {
    let (client, transport) = try makeStubbedAPIClient(
        responseBody: #"{"id":"receipt-123"}"#,
        statusCode: 202
    )
    let repository = RemoteEnquiryRepository(apiClient: client)
    let enquiry = Enquiry(
        productId: 1,
        name: "Ada Lovelace",
        email: "ada@example.test",
        phone: "+1 (555) 010-1234",
        message: "I have a question."
    )

    let receipt = try await repository.submit(enquiry)
    let request = try await capturedRequest(from: transport)
    let body = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

    #expect(receipt == EnquiryReceipt(id: "receipt-123"))
    #expect(request.url?.absoluteString == "https://api.example.test/api/v1/enquiries")
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(Set(json.keys) == Set(["productId", "name", "email", "phone", "message"]))
    #expect(json["productId"] as? Int == 1)
    #expect(json["name"] as? String == "Ada Lovelace")
    #expect(json["email"] as? String == "ada@example.test")
    #expect(json["phone"] as? String == "+1 (555) 010-1234")
    #expect(json["message"] as? String == "I have a question.")
}

@Test
func requestAndResponseBodiesAreNotEchoedInMappedErrors() async throws {
    let customerEmail = "private-customer@example.test"
    let customerMessage = "private enquiry text"
    let responseBody = """
    {"error":{"code":"UPSTREAM_UNAVAILABLE","message":"\(customerMessage)"},"echo":"\(customerEmail)"}
    """
    let (client, _) = try makeStubbedAPIClient(
        responseBody: responseBody,
        statusCode: 502
    )
    let enquiry = Enquiry(
        productId: 1,
        name: "Private Customer",
        email: customerEmail,
        message: customerMessage
    )
    let error = await captureDataLayerError {
        try await RemoteEnquiryRepository(apiClient: client).submit(enquiry)
    }
    let appError = try #require(error as? AppError)

    #expect(appError == .serverUnavailable)
    #expect(!appError.message.contains(customerEmail))
    #expect(!appError.message.contains(customerMessage))
    #expect(!String(describing: appError).contains(customerEmail))
    #expect(!String(describing: appError).contains(customerMessage))
}
