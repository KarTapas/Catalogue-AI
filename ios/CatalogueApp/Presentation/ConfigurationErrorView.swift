import SwiftUI

struct ConfigurationErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: Spacing.s16) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.title)
                .accessibilityHidden(true)
            Text("Configuration error")
                .font(Typography.title)
            Text(message)
                .font(Typography.body)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Palette.error)
        .padding(Spacing.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
    }
}

#Preview {
    ConfigurationErrorView(message: "The API URL is not configured.")
}
