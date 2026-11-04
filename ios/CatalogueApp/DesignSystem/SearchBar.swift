import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let canSearch: Bool
    let onSearch: () -> Void

    var body: some View {
        VStack(spacing: Spacing.s8) {
            HStack(spacing: Spacing.s8) {
                TextField("Search products", text: $text)
                    .font(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit(performSearch)
                    .accessibilityLabel("Search products")

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.body)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(Spacing.s12)
            .background(
                Palette.surface,
                in: RoundedRectangle(cornerRadius: Radius.r12)
            )

            PrimaryButton(title: "Search", action: performSearch)
                .disabled(!canSearch)
        }
    }

    private func performSearch() {
        guard canSearch else {
            return
        }
        onSearch()
    }
}

#Preview {
    SearchBar(
        text: .constant("jacket"),
        canSearch: true,
        onSearch: {}
    )
    .padding()
}
