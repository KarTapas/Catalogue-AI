import SwiftUI

struct SearchPlaceholderView: View {
    let query: String

    var body: some View {
        Text("Search placeholder: \(query)")
            .font(Typography.body)
            .foregroundStyle(Palette.textPrimary)
            .padding(Spacing.s16)
    }
}
