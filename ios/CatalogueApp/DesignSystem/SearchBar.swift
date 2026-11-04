import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let canSearch: Bool
    let onSearch: () -> Void
    let validationMessage: String?

    init(
        text: Binding<String>,
        canSearch: Bool,
        onSearch: @escaping () -> Void,
        validationMessage: String? = nil
    ) {
        _text = text
        self.canSearch = canSearch
        self.onSearch = onSearch
        self.validationMessage = validationMessage
    }

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

            if let validationMessage {
                Text(verbatim: validationMessage)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.error)
                    .padding(.horizontal, Spacing.s4)
            }

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
