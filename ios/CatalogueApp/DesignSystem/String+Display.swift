import Foundation

extension String {
    func capitalizedWordsForDisplay() -> String {
        split(whereSeparator: \.isWhitespace)
            .map { word in
                guard let firstCharacter = word.first else {
                    return ""
                }
                return String(firstCharacter).uppercased()
                    + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}
