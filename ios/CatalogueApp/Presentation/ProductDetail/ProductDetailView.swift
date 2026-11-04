import CatalogueDomain
import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel
    private let submitEnquiry: SubmitEnquiryUseCase

    #if DEBUG
    private let debugPreviewMode: EnquiryPreviewMode?
    #endif

    #if DEBUG
    init(
        viewModel: ProductDetailViewModel,
        submitEnquiry: SubmitEnquiryUseCase,
        debugPreviewMode: EnquiryPreviewMode? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.submitEnquiry = submitEnquiry
        self.debugPreviewMode = debugPreviewMode
    }
    #else
    init(viewModel: ProductDetailViewModel, submitEnquiry: SubmitEnquiryUseCase) {
        _viewModel = State(initialValue: viewModel)
        self.submitEnquiry = submitEnquiry
    }
    #endif

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
            #if DEBUG
            if debugPreviewMode != nil {
                viewModel.enquire()
            }
            #endif
        }
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isEnquirySheetPresented) {
            if let product = viewModel.content.value {
                #if DEBUG
                EnquiryView(
                    viewModel: EnquiryViewModel(
                        product: EnquiryProduct(product: product),
                        submitEnquiry: submitEnquiry
                    ),
                    debugPreviewMode: debugPreviewMode
                )
                #else
                EnquiryView(
                    viewModel: EnquiryViewModel(
                        product: EnquiryProduct(product: product),
                        submitEnquiry: submitEnquiry
                    )
                )
                #endif
            }
        }
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }
}
