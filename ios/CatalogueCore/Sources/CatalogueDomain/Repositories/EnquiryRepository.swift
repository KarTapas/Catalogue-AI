import Foundation

public protocol EnquiryRepository: Sendable {
    func submit(_ enquiry: Enquiry) async throws -> EnquiryReceipt
}
