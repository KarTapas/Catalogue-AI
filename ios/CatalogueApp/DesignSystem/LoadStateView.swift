import CatalogueDomain
import SwiftUI

struct LoadStateView<Value, Content: View>: View {
    let state: LoadState<Value>
    let emptyMessage: String
    let isEmpty: (Value) -> Bool
    let onRetry: () -> Void
    private let content: (Value) -> Content
    private let errorMessage: (AppError) -> String

    init(
        state: LoadState<Value>,
        emptyMessage: String = "No items to show.",
        isEmpty: @escaping (Value) -> Bool = { _ in false },
        onRetry: @escaping () -> Void,
        errorMessage: @escaping (AppError) -> String = { $0.message },
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.emptyMessage = emptyMessage
        self.isEmpty = isEmpty
        self.onRetry = onRetry
        self.errorMessage = errorMessage
        self.content = content
    }

    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
                    .tint(Palette.brand)
                    .accessibilityLabel("Loading")
            case .loaded(let value):
                if isEmpty(value) {
                    VStack(spacing: Spacing.s8) {
                        Image(systemName: "tray")
                            .accessibilityHidden(true)
                        Text(emptyMessage)
                            .font(Typography.body)
                    }
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityElement(children: .combine)
                } else {
                    content(value)
                }
            case .failed(let error):
                VStack(spacing: Spacing.s16) {
                    Text(errorMessage(error))
                        .font(Typography.body)
                        .foregroundStyle(Palette.error)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: "Retry", action: onRetry)
                }
                .padding(Spacing.s24)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Loading") {
    LoadStateView<[String], Text>(
        state: .loading,
        onRetry: {}
    ) { items in
        Text(items.joined(separator: ", "))
    }
}
