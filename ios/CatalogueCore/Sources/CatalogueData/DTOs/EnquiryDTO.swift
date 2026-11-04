import CatalogueDomain
import Foundation

struct EnquiryRequestDTO: Encodable {
    let productId: Int
    let name: String
    let email: String
    let phone: String?
    let message: String

    init(_ enquiry: Enquiry) {
        productId = enquiry.productId
        name = enquiry.name
        email = enquiry.email
        phone = enquiry.phone
        message = enquiry.message
    }
}

struct EnquiryReceiptDTO: Decodable {
    let id: String
}
