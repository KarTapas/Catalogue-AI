import CatalogueDomain
import Observation

@Observable
@MainActor
final class ProductDetailViewModel {
    let productID: Int
    private(set) var content: LoadState<Product> = .idle
    var isEnquirySheetPresented = false

    private let getProduct: GetProductUseCase

    init(productID: Int, getProduct: GetProductUseCase) {
        self.productID = productID
        self.getProduct = getProduct
    }

    var canEnquire: Bool {
        content.value != nil
    }

    var enquireButtonAccessibilityLabel: String {
        guard let product = content.value else {
            return "Enquire about product"
        }
        return ProductDetailDisplay.enquireButtonLabel(for: product.title)
    }

    func load() async {
        guard case .idle = content else {
            return
        }
        await fetch()
    }

    func retry() async {
        guard case .failed = content else {
            return
        }
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    func enquire() {
        guard content.value != nil else {
            return
        }
        isEnquirySheetPresented = true
    }

    private func fetch() async {
        guard !content.isLoading else {
            return
        }

        let previousState = content
        content = .loading

        do {
            content = .loaded(try await getProduct.execute(id: productID))
        } catch is CancellationError {
            content = previousState
        } catch let error as AppError {
            content = .failed(error)
        } catch {
            content = .failed(.unexpected)
        }
    }
}

enum ProductDetailDisplay {
    static func errorMessage(for error: AppError) -> String {
        if case .notFound = error {
            return "This product is no longer available"
        }
        return error.message
    }

    static func categoryLabel(for category: String) -> String {
        category.capitalizedWordsForDisplay()
    }

    static func enquireButtonLabel(for productTitle: String) -> String {
        "Enquire about \(productTitle)"
    }
}
