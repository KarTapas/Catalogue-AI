import SwiftUI

struct ProductPlaceholderView: View {
    let id: Int

    var body: some View {
        Text("Product placeholder: \(id)")
            .font(Typography.body)
            .foregroundStyle(Palette.textPrimary)
            .padding(Spacing.s16)
    }
}
