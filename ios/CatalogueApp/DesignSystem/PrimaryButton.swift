import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(Palette.surface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s12)
                .background(
                    Palette.brand,
                    in: RoundedRectangle(cornerRadius: Radius.r12)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

#Preview {
    PrimaryButton(title: "Retry", action: {})
        .padding()
}
