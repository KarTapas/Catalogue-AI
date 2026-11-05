import SwiftUI

struct CategoryChip: View {
    let category: String
    let action: () -> Void

    private var displayName: String {
        category.capitalizedWordsForDisplay()
    }

    var body: some View {
        Button(action: action) {
            Text(displayName)
                .font(Typography.body)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, Spacing.s12)
                .padding(.vertical, Spacing.s8)
                .background(Palette.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Category: \(displayName)"))
    }
}

#Preview {
    CategoryChip(category: "men's clothing", action: {})
        .padding()
}
