import SwiftUI

struct FormField<Field: View>: View {
    let title: String
    let errorMessage: String?
    private let accessibilityLabel: String
    private let field: Field

    init(
        title: String,
        accessibilityLabel: String? = nil,
        errorMessage: String? = nil,
        @ViewBuilder field: () -> Field
    ) {
        self.title = title
        self.accessibilityLabel = accessibilityLabel ?? title
        self.errorMessage = errorMessage
        self.field = field()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(verbatim: title)
                .font(Typography.headline)
                .foregroundStyle(Palette.textPrimary)

            accessibleField
                .font(Typography.body)
                .foregroundStyle(Palette.textPrimary)
                .padding(Spacing.s12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Palette.surface,
                    in: RoundedRectangle(cornerRadius: Radius.r12)
                )

            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var accessibleField: some View {
        if let errorMessage {
            field
                .accessibilityLabel(Text(verbatim: accessibilityLabel))
                .accessibilityHint(Text(verbatim: errorMessage))
        } else {
            field
                .accessibilityLabel(Text(verbatim: accessibilityLabel))
        }
    }
}
