import CatalogueDomain
import Foundation
import Testing
@testable import CatalogueApp

@Test @MainActor
func productDetailViewModelStartsIdle() {
    let repository = FakeProductDetailRepository(outcomes: [])
    let viewModel = makeProductDetailViewModel(productID: 1, repository: repository)

    #expect(viewModel.content == .idle)
    #expect(viewModel.isEnquirySheetPresented == false)
    #expect(viewModel.canEnquire == false)
}

@Test @MainActor
func productDetailLoadPublishesFullProductAndUsesExactID() async {
    let product = makeDetailProduct(id: 47)
    let repository = FakeProductDetailRepository(
        outcomes: [.success(product)],
        heldProductCalls: [1]
    )
    let viewModel = makeProductDetailViewModel(productID: 47, repository: repository)

    #expect(viewModel.content == .idle)
    let loadTask = Task {
        await viewModel.load()
    }
    await repository.waitForProductCallCount(1)
    #expect(viewModel.content == .loading)

    let idsWhileLoading = await repository.recordedProductIDs()
    #expect(idsWhileLoading == [47])

    await repository.completeProductCall(1)
    await loadTask.value

    #expect(viewModel.content == .loaded(product))
    #expect(viewModel.content.value == product)
    #expect(viewModel.canEnquire)
}

@Test @MainActor
func productDetailLoadPreservesTheSameAppError() async {
    let error = AppError.serverUnavailable
    let repository = FakeProductDetailRepository(outcomes: [.failure(error)])
    let viewModel = makeProductDetailViewModel(productID: 12, repository: repository)

    await viewModel.load()

    #expect(viewModel.content == .failed(error))
}

@Test @MainActor
func productDetailUnexpectedErrorsMapToUnexpected() async {
    let repository = FakeProductDetailRepository(outcomes: [.unexpectedFailure])
    let viewModel = makeProductDetailViewModel(productID: 12, repository: repository)

    await viewModel.load()

    #expect(viewModel.content == .failed(.unexpected))
}

@Test @MainActor
func productDetailNotFoundAndUnreachableMessagesAreUserFriendly() {
    #expect(
        ProductDetailDisplay.errorMessage(for: .notFound)
            == "This product is no longer available"
    )
    #expect(
        ProductDetailDisplay.errorMessage(for: .unreachable)
            == AppError.unreachable.message
    )
    #expect(
        ProductDetailDisplay.errorMessage(for: .unreachable)
            .contains("backend may not be running")
    )
}

@Test @MainActor
func productDetailRetryRecoversAfterFailure() async {
    let product = makeDetailProduct(id: 9)
    let repository = FakeProductDetailRepository(
        outcomes: [.failure(.unreachable), .success(product)]
    )
    let viewModel = makeProductDetailViewModel(productID: 9, repository: repository)

    await viewModel.load()
    #expect(viewModel.content == .failed(.unreachable))

    await viewModel.retry()

    #expect(viewModel.content == .loaded(product))
    let ids = await repository.recordedProductIDs()
    #expect(ids == [9, 9])
}

@Test @MainActor
func productDetailLoadDoesNotDuplicateInFlightOrLoadedRequests() async {
    let product = makeDetailProduct(id: 21)
    let repository = FakeProductDetailRepository(
        outcomes: [.success(product)],
        heldProductCalls: [1]
    )
    let viewModel = makeProductDetailViewModel(productID: 21, repository: repository)

    let loadTask = Task {
        await viewModel.load()
    }
    await repository.waitForProductCallCount(1)
    await viewModel.load()
    let idsWhileLoading = await repository.recordedProductIDs()
    #expect(idsWhileLoading == [21])

    await repository.completeProductCall(1)
    await loadTask.value
    await viewModel.load()

    #expect(viewModel.content == .loaded(product))
    let idsAfterLoad = await repository.recordedProductIDs()
    #expect(idsAfterLoad == [21])
}

@Test @MainActor
func productDetailCancellationRestoresPreviousStateInsteadOfFailing() async {
    let repository = FakeProductDetailRepository(outcomes: [.cancelled])
    let viewModel = makeProductDetailViewModel(productID: 5, repository: repository)

    await viewModel.load()

    #expect(viewModel.content == .idle)
}

@Test @MainActor
func productDetailEnquiryRequiresLoadedProduct() async {
    let product = makeDetailProduct(id: 31)
    let repository = FakeProductDetailRepository(
        outcomes: [.success(product)],
        heldProductCalls: [1]
    )
    let viewModel = makeProductDetailViewModel(productID: 31, repository: repository)

    viewModel.enquire()
    #expect(viewModel.isEnquirySheetPresented == false)

    let loadTask = Task {
        await viewModel.load()
    }
    await repository.waitForProductCallCount(1)
    viewModel.enquire()
    #expect(viewModel.content == .loading)
    #expect(viewModel.isEnquirySheetPresented == false)

    await repository.completeProductCall(1)
    await loadTask.value
    viewModel.enquire()

    #expect(viewModel.canEnquire)
    #expect(viewModel.isEnquirySheetPresented)
    #expect(
        viewModel.enquireButtonAccessibilityLabel
            == ProductDetailDisplay.enquireButtonLabel(for: product.title)
    )
}

@Test @MainActor
func productDetailEnquiryDoesNotPresentAfterFailure() async {
    let repository = FakeProductDetailRepository(outcomes: [.failure(.notFound)])
    let viewModel = makeProductDetailViewModel(productID: 9999, repository: repository)

    await viewModel.load()
    viewModel.enquire()

    #expect(viewModel.content == .failed(.notFound))
    #expect(viewModel.canEnquire == false)
    #expect(viewModel.isEnquirySheetPresented == false)
}

@Test
func productDetailEnquireLabelIncludesTheProductTitle() {
    #expect(
        ProductDetailDisplay.enquireButtonLabel(for: "Trail Backpack")
            == "Enquire about Trail Backpack"
    )
}

@Test
func productDetailCategoryLabelCapitalizesWithoutChangingTheOriginal() {
    let original = "men's clothing"

    #expect(ProductDetailDisplay.categoryLabel(for: original) == "Men's Clothing")
    #expect(original == "men's clothing")
}

@MainActor
private func makeProductDetailViewModel(
    productID: Int,
    repository: any ProductRepository
) -> ProductDetailViewModel {
    ProductDetailViewModel(
        productID: productID,
        getProduct: GetProductUseCase(repository: repository)
    )
}

private func makeDetailProduct(id: Int) -> Product {
    Product(
        id: id,
        title: "Trail Backpack \(id)",
        description: "A sturdy backpack for everyday use.",
        category: "men's clothing",
        price: Money(
            amount: Decimal(string: "109.95", locale: Locale(identifier: "en_US_POSIX"))
                ?? .zero,
            currencyCode: "USD"
        ),
        imageURL: URL(string: "https://images.example.test/product-\(id).png"),
        rating: Rating(rate: 4.8, count: 123)
    )
}

private enum ProductOutcome: Sendable {
    case success(Product)
    case failure(AppError)
    case unexpectedFailure
    case cancelled

    func get() throws -> Product {
        switch self {
        case .success(let product):
            product
        case .failure(let error):
            throw error
        case .unexpectedFailure:
            throw UnexpectedProductRepositoryError()
        case .cancelled:
            throw CancellationError()
        }
    }
}

private struct UnexpectedProductRepositoryError: Error, Sendable {}

private actor FakeProductDetailRepository: ProductRepository {
    private let outcomes: [ProductOutcome]
    private let heldProductCalls: Set<Int>
    private var continuations: [Int: CheckedContinuation<Product, any Error>] = [:]
    private var callWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]
    private var requestedIDs: [Int] = []

    init(outcomes: [ProductOutcome], heldProductCalls: Set<Int> = []) {
        self.outcomes = outcomes
        self.heldProductCalls = heldProductCalls
    }

    func featured() async throws -> [Product] {
        []
    }

    func categories() async throws -> [String] {
        []
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        CategoryProducts(category: name, topRated: [], others: [])
    }

    func search(query: String) async throws -> [Product] {
        []
    }

    func product(id: Int) async throws -> Product {
        let callNumber = requestedIDs.count + 1
        requestedIDs.append(id)
        resumeCallWaiters(upTo: callNumber)

        guard outcomes.indices.contains(callNumber - 1) else {
            throw AppError.unexpected
        }
        let outcome = outcomes[callNumber - 1]
        guard heldProductCalls.contains(callNumber) else {
            return try outcome.get()
        }

        return try await withCheckedThrowingContinuation { continuation in
            continuations[callNumber] = continuation
        }
    }

    func waitForProductCallCount(_ count: Int) async {
        guard requestedIDs.count < count else {
            return
        }
        await withCheckedContinuation { continuation in
            callWaiters[count, default: []].append(continuation)
        }
    }

    func completeProductCall(_ callNumber: Int) {
        guard let continuation = continuations.removeValue(forKey: callNumber) else {
            return
        }
        guard outcomes.indices.contains(callNumber - 1) else {
            continuation.resume(throwing: AppError.unexpected)
            return
        }
        do {
            continuation.resume(returning: try outcomes[callNumber - 1].get())
        } catch {
            continuation.resume(throwing: error)
        }
    }

    func recordedProductIDs() -> [Int] {
        requestedIDs
    }

    private func resumeCallWaiters(upTo count: Int) {
        for expectedCount in callWaiters.keys.filter({ $0 <= count }) {
            guard let waiters = callWaiters.removeValue(forKey: expectedCount) else {
                continue
            }
            waiters.forEach { $0.resume() }
        }
    }
}
