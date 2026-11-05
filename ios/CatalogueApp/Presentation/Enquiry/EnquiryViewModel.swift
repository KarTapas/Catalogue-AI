import CatalogueDomain
import Foundation
import Observation

struct EnquiryProduct: Equatable, Sendable {
    let id: Int
    let title: String

    init(id: Int, title: String) {
        self.id = id
        self.title = title
    }

    init(product: Product) {
        self.init(id: product.id, title: product.title)
    }
}

enum EnquiryField: String, CaseIterable, Hashable, Sendable {
    case name
    case email
    case phone
    case message
}

@Observable
@MainActor
final class EnquiryViewModel {
    enum State: Equatable {
        case editing
        case submitting
        case succeeded(EnquiryReceipt)
        case failed(AppError)
    }

    let product: EnquiryProduct
    private(set) var state: State = .editing
    var name = ""
    var email = ""
    var phone = ""
    var message = ""
    private(set) var touchedFields: Set<EnquiryField> = []
    private(set) var hasAttemptedSubmit = false

    private let submitEnquiry: SubmitEnquiryUseCase
    private var serverFieldErrors: [String: String] = [:]

    init(product: EnquiryProduct, submitEnquiry: SubmitEnquiryUseCase) {
        self.product = product
        self.submitEnquiry = submitEnquiry
    }

    var isSubmitting: Bool {
        if case .submitting = state {
            return true
        }
        return false
    }

    var canSubmit: Bool {
        !isSubmitting
    }

    var fieldErrors: [String: String] {
        let validationErrors = EnquiryValidator.validate(currentEnquiry)
        var visibleErrors: [String: String] = [:]

        for field in EnquiryField.allCases {
            guard hasAttemptedSubmit || touchedFields.contains(field) else {
                continue
            }

            if let serverError = serverFieldErrors[field.rawValue] {
                visibleErrors[field.rawValue] = serverError
            } else if let validationError = validationErrors[field.rawValue] {
                visibleErrors[field.rawValue] = validationError
            }
        }

        return visibleErrors
    }

    var failureMessage: String? {
        guard case .failed(let error) = state else {
            return nil
        }

        switch error {
        case .validation(let fields):
            let fieldNames = Set(EnquiryField.allCases.map(\.rawValue))
            return fields.keys.contains(where: { !fieldNames.contains($0) })
                ? error.message
                : nil
        case .rateLimited:
            return "Too many enquiries, please try again in a minute"
        default:
            return error.message
        }
    }

    func markTouched(_ field: EnquiryField) {
        touchedFields.insert(field)
        serverFieldErrors.removeValue(forKey: field.rawValue)
        if case .failed = state {
            state = .editing
        }
    }

    func submit() async {
        guard canSubmit else {
            return
        }

        hasAttemptedSubmit = true
        serverFieldErrors.removeAll()
        let enquiry = currentEnquiry
        guard EnquiryValidator.validate(enquiry).isEmpty else {
            state = .editing
            return
        }

        state = .submitting

        do {
            let receipt = try await submitEnquiry.execute(enquiry)
            clearFormData()
            state = .succeeded(receipt)
        } catch is CancellationError {
            state = .editing
        } catch let error as AppError {
            if case .validation(let fields) = error {
                serverFieldErrors = fields
            }
            state = .failed(error)
        } catch {
            state = .failed(.unexpected)
        }
    }

    #if DEBUG
    func prefillDebugSubmission() {
        name = "Test Customer"
        email = "test.customer@example.test"
        message = "Hello from the app"
    }
    #endif

    private var currentEnquiry: Enquiry {
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        return Enquiry(
            productId: product.id,
            name: name,
            email: email,
            phone: trimmedPhone.isEmpty ? nil : phone,
            message: message
        )
    }

    private func clearFormData() {
        name = ""
        email = ""
        phone = ""
        message = ""
        touchedFields.removeAll()
        hasAttemptedSubmit = false
        serverFieldErrors.removeAll()
    }
}

enum EnquiryText {
    static let messageLimit = 2_000

    static func messageCharacterCount(_ message: String) -> String {
        "\(message.utf16.count) / \(messageLimit) characters"
    }

    static func thankYouMessage(for title: String) -> String {
        "We have received your enquiry about \(title) and will be in touch soon."
    }
}

#if DEBUG
enum EnquiryPreviewMode: Hashable {
    case form
    case submit
    case errors
}
#endif
