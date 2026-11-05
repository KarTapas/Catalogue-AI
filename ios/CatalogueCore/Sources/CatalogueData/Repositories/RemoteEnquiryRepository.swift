import CatalogueDomain
import Foundation

public struct RemoteEnquiryRepository: EnquiryRepository, Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func submit(_ enquiry: Enquiry) async throws -> EnquiryReceipt {
        let dto = try await apiClient.post(
            pathSegments: ["enquiries"],
            body: EnquiryRequestDTO(enquiry),
            responseType: EnquiryReceiptDTO.self
        )
        return EnquiryReceipt(id: dto.id)
    }
}
