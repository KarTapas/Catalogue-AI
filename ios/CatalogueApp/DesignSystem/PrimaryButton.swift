import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s8) {
                if isLoading {
                    ProgressView()
                        .tint(Palette.surface)
                        .accessibilityHidden(true)
                }

                Text(verbatim: title)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.surface)
            }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s12)
                .background(
                    Palette.brand,
                    in: RoundedRectangle(cornerRadius: Radius.r12)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .disabled(isLoading)
    }
}

#Preview {
    PrimaryButton(title: "Retry", action: {})
        .padding()
}
