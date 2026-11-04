import Foundation
import CatalogueDomain
import Testing

@Test
func moneyUsesAnExactDecimalAndItsCurrencyCode() throws {
    let amount = try #require(
        Decimal(string: "109.95", locale: Locale(identifier: "en_US_POSIX"))
    )
    let money = Money(amount: amount, currencyCode: "EUR")
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "EUR"
    let expectedFormattedAmount = try #require(
        formatter.string(from: NSDecimalNumber(decimal: amount))
    )

    #expect(money.amount == amount)
    #expect(NSDecimalNumber(decimal: money.amount).stringValue == "109.95")
    #expect(money.formattedAmount == expectedFormattedAmount)
}

@Test
func everyAppErrorHasAUserFriendlyMessage() {
    let errors: [AppError] = [
        .unreachable,
        .notFound,
        .validation(fields: ["name": "Enter your name."]),
        .rateLimited,
        .serverUnavailable,
        .unexpected,
    ]

    #expect(errors.allSatisfy { !$0.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    #expect(AppError.unreachable.message.contains("backend may not be running"))
}

@Test
func enquiryValidatorAcceptsValidAndOptionalPhoneValues() {
    let enquiryWithoutPhone = Enquiry(
        productId: 1,
        name: "Ada Lovelace",
        email: "ada@example.test",
        message: "I have a question."
    )

    #expect(EnquiryValidator.validate(makeEnquiry(phone: "+1 (555) 010-1234")).isEmpty)
    #expect(EnquiryValidator.validate(enquiryWithoutPhone).isEmpty)
}

@Test
func enquiryValidatorRejectsEmptyLongAndControlledNames() {
    let emptyNameErrors = EnquiryValidator.validate(makeEnquiry(name: "   "))
    let longNameErrors = EnquiryValidator.validate(
        makeEnquiry(name: String(repeating: "A", count: 101))
    )
    let controlledNameErrors = EnquiryValidator.validate(makeEnquiry(name: "Ada\nLovelace"))

    #expect(emptyNameErrors["name"] != nil)
    #expect(longNameErrors["name"] != nil)
    #expect(controlledNameErrors["name"] != nil)
}

@Test
func enquiryValidatorRejectsInvalidAndOverlongEmails() {
    let invalidEmailErrors = EnquiryValidator.validate(makeEnquiry(email: "not-an-email"))
    let longEmail = String(repeating: "a", count: 242) + "@example.test"
    let longEmailErrors = EnquiryValidator.validate(makeEnquiry(email: longEmail))

    #expect(invalidEmailErrors["email"] != nil)
    #expect(longEmail.count == 255)
    #expect(longEmailErrors["email"] != nil)
}

@Test
func enquiryValidatorRejectsInvalidAndOverlongPhones() {
    let invalidPhoneErrors = EnquiryValidator.validate(makeEnquiry(phone: "555-ABC"))
    let longPhoneErrors = EnquiryValidator.validate(
        makeEnquiry(phone: String(repeating: "1", count: 31))
    )

    #expect(invalidPhoneErrors["phone"] != nil)
    #expect(longPhoneErrors["phone"] != nil)
}

@Test
func enquiryValidatorRejectsEmptyLongAndUnsupportedControlMessages() {
    let emptyMessageErrors = EnquiryValidator.validate(makeEnquiry(message: " \n "))
    let longMessageErrors = EnquiryValidator.validate(
        makeEnquiry(message: String(repeating: "M", count: 2_001))
    )
    let controlledMessageErrors = EnquiryValidator.validate(makeEnquiry(message: "Hello\u{0001}"))

    #expect(emptyMessageErrors["message"] != nil)
    #expect(longMessageErrors["message"] != nil)
    #expect(controlledMessageErrors["message"] != nil)
}

@Test
func enquiryValidatorRejectsNonPositiveProductIds() {
    #expect(EnquiryValidator.validate(makeEnquiry(productId: 0))["productId"] != nil)
}

@Test
func searchQueryTrimsAndEnforcesItsLengthRange() throws {
    let query = try SearchQuery(" \n jacket \t ")

    #expect(query.value == "jacket")
    #expect(throws: AppError.self) {
        try SearchQuery("a")
    }
    #expect(throws: AppError.self) {
        try SearchQuery(String(repeating: "a", count: 101))
    }
}

private func makeEnquiry(
    productId: Int = 1,
    name: String = "Ada Lovelace",
    email: String = "ada@example.test",
    phone: String? = nil,
    message: String = "I have a question."
) -> Enquiry {
    Enquiry(
        productId: productId,
        name: name,
        email: email,
        phone: phone,
        message: message
    )
}
