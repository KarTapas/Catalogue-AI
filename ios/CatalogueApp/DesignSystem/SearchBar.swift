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
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack(spacing: Spacing.s8) {
                Image(systemName: "magnifyingglass")
                    .font(Typography.body)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)

                TextField("Search products", text: $text)
                    .font(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit(performSearch)
                    .accessibilityLabel("Search products")
                    .layoutPriority(1)

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.body)
                            .foregroundStyle(Palette.textSecondary)
                            .frame(
                                width: Spacing.minimumTapTarget,
                                height: Spacing.minimumTapTarget
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }

                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(Typography.body)
                        .foregroundStyle(canSearch ? Palette.surface : Palette.textSecondary)
                        .frame(
                            width: Spacing.minimumTapTarget,
                            height: Spacing.minimumTapTarget
                        )
                        .background(
                            canSearch ? Palette.brand : Palette.background,
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .opacity(canSearch ? 1 : Opacity.disabled)
                .disabled(!canSearch)
                .accessibilityLabel("Search")
                .accessibilityHint("Searches the catalogue")
            }
            .padding(.leading, Spacing.s12)
            .padding(.trailing, Spacing.s4)
            .frame(minHeight: Spacing.searchBarMinimumHeight)
            .background(
                Palette.surface,
                in: RoundedRectangle(cornerRadius: Radius.r12)
            )

            if let validationMessage {
                Text(verbatim: validationMessage)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.s4)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    private func performSearch() {
        guard canSearch else {
            return
        }
        onSearch()
    }
}

#Preview("Empty") {
    SearchBar(
        text: .constant(""),
        canSearch: false,
        onSearch: {}
    )
    .padding()
}

#Preview("Valid text") {
    SearchBar(
        text: .constant("jacket"),
        canSearch: true,
        onSearch: {}
    )
    .padding()
}

#Preview("One character") {
    SearchBar(
        text: .constant("j"),
        canSearch: false,
        onSearch: {},
        validationMessage: "Enter a search query between 2 and 100 characters."
    )
    .padding()
}

#Preview("Large text") {
    SearchBar(
        text: .constant("jacket"),
        canSearch: true,
        onSearch: {}
    )
    .padding()
    .environment(\.dynamicTypeSize, .accessibility3)
}
