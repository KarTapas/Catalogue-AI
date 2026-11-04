import Foundation

public struct SubmitEnquiryUseCase: Sendable {
    private let repository: any EnquiryRepository

    public init(repository: any EnquiryRepository) {
        self.repository = repository
    }

    public func execute(_ enquiry: Enquiry) async throws -> EnquiryReceipt {
        let fields = EnquiryValidator.validate(enquiry)
        guard fields.isEmpty else {
            throw AppError.validation(fields: fields)
        }

        let trimmedEnquiry = Enquiry(
            productId: enquiry.productId,
            name: enquiry.name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: enquiry.email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: enquiry.phone?.trimmingCharacters(in: .whitespacesAndNewlines),
            message: enquiry.message.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return try await repository.submit(trimmedEnquiry)
    }
}
