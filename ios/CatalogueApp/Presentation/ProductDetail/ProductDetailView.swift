import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel

    init(viewModel: ProductDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LoadStateView(
                state: viewModel.content,
                emptyMessage: "No product details available.",
                isEmpty: { _ in false },
                onRetry: retry,
                errorMessage: { ProductDetailDisplay.errorMessage(for: $0) }
            ) { product in
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    RemoteImage(
                        url: product.imageURL,
                        accessibilityLabel: "\(product.title) image"
                    )
                    .frame(height: 280)
                    .background(
                        Palette.surface,
                        in: RoundedRectangle(cornerRadius: Radius.r16)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.r16))

                    Text(verbatim: product.title)
                        .font(Typography.title)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s16) {
                        Text(verbatim: product.price.formattedAmount)
                            .font(Typography.headline)
                            .foregroundStyle(Palette.textPrimary)
                            .accessibilityLabel(
                                Text(verbatim: "Price \(product.price.formattedAmount)")
                            )

                        RatingView(rating: product.rating)
                    }
                    .accessibilityElement(children: .combine)

                    Text(verbatim: ProductDetailDisplay.categoryLabel(for: product.category))
                        .font(Typography.body)
                        .foregroundStyle(Palette.textSecondary)

                    Text(verbatim: product.description)
                        .font(Typography.body)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s16)
        }
        .background(Palette.background)
        .refreshable {
            await viewModel.refresh()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton(title: "Enquire", action: viewModel.enquire)
                .disabled(!viewModel.canEnquire)
                .accessibilityLabel(
                    Text(verbatim: viewModel.enquireButtonAccessibilityLabel)
                )
                .padding(.horizontal, Spacing.s16)
                .padding(.vertical, Spacing.s12)
                .background(Palette.background)
        }
        .task {
            await viewModel.load()
        }
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isEnquirySheetPresented) {
            if let product = viewModel.content.value {
                EnquiryPlaceholderView(
                    productID: product.id,
                    productTitle: product.title
                ) {
                    viewModel.isEnquirySheetPresented = false
                }
            }
        }
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }
}

private struct EnquiryPlaceholderView: View {
    let productID: Int
    let productTitle: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Text("Enquiry")
                .font(Typography.title)
                .foregroundStyle(Palette.textPrimary)

            Text("placeholder, replaced in T12")
                .font(Typography.headline)
                .foregroundStyle(Palette.textSecondary)

            Text(verbatim: "Enquiring about \(productTitle) (product \(productID))")
                .font(Typography.body)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Spacing.s16)

            PrimaryButton(title: "Close", action: onClose)
        }
        .padding(Spacing.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.background)
    }
}
