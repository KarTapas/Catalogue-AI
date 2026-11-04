import Foundation

public enum EnquiryValidator {
    private static let emailPattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#

    public static func validate(_ enquiry: Enquiry) -> [String: String] {
        var fields: [String: String] = [:]

        if enquiry.productId <= 0 {
            fields["productId"] = "Select a valid product."
        }

        let trimmedName = enquiry.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if containsControlCharacters(enquiry.name) {
            fields["name"] = "Name must not contain control characters."
        } else if trimmedName.isEmpty {
            fields["name"] = "Enter your name."
        } else if trimmedName.count > 100 {
            fields["name"] = "Name must be 100 characters or fewer."
        }

        if enquiry.email.count > 254
            || containsControlCharacters(enquiry.email)
            || enquiry.email.range(
                of: emailPattern,
                options: [.regularExpression, .caseInsensitive]
            ) == nil
        {
            fields["email"] = "Enter a valid email address of 254 characters or fewer."
        }

        if let phone = enquiry.phone {
            if phone.count > 30 {
                fields["phone"] = "Phone number must be 30 characters or fewer."
            } else if !phone.unicodeScalars.allSatisfy(isAllowedPhoneScalar) {
                fields["phone"] = "Use only digits, spaces, +, -, ( or ) in the phone number."
            }
        }

        let trimmedMessage = enquiry.message.trimmingCharacters(in: .whitespacesAndNewlines)
        if containsUnsupportedMessageControls(enquiry.message) {
            fields["message"] = "Message contains an unsupported control character."
        } else if trimmedMessage.isEmpty {
            fields["message"] = "Enter a message."
        } else if trimmedMessage.count > 2_000 {
            fields["message"] = "Message must be 2,000 characters or fewer."
        }

        return fields
    }

    private static func containsControlCharacters(_ value: String) -> Bool {
        value.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
    }

    private static func containsUnsupportedMessageControls(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            CharacterSet.controlCharacters.contains(scalar)
                && scalar.value != 0x0A
                && scalar.value != 0x0D
        }
    }

    private static func isAllowedPhoneScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x20, 0x28, 0x29, 0x2B, 0x2D, 0x30...0x39:
            true
        default:
            false
        }
    }
}
