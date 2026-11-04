import SwiftUI

struct CategoryPlaceholderView: View {
    let category: String

    var body: some View {
        Text("Category placeholder: \(category)")
            .font(Typography.body)
            .foregroundStyle(Palette.textPrimary)
            .padding(Spacing.s16)
    }
}
