import CatalogueDomain
import Foundation
import Testing
@testable import CatalogueApp

@Test
@MainActor
func categoryViewModelStartsIdle() {
    let viewModel = makeCategoryViewModel(
        name: "electronics",
        repository: FakeCategoryProductRepository()
    )

    #expect(viewModel.content == .idle)
}

@Test
@MainActor
func loadPreservesBackendSplitOrderAndOriginalCategoryName() async {
    let products = makeCategoryProducts(
        topRatedIDs: [8, 3, 6],
        otherIDs: [4, 1]
    )
    let repository = FakeCategoryProductRepository(outcomes: [.success(products)])
    let viewModel = makeCategoryViewModel(
        name: "men's clothing",
        repository: repository
    )

    await viewModel.load()
    await viewModel.load()

    #expect(viewModel.content == .loaded(products))
    #expect(viewModel.displayTitle == "Men's Clothing")
    #expect(products.topRated.map(\.id) == [8, 3, 6])
    #expect(products.others.map(\.id) == [4, 1])
    #expect(await repository.requestedCategoryNames() == ["men's clothing"])
    #expect(await repository.requestCount() == 1)
}

@Test
@MainActor
func loadKeepsThreeTopRatedAndAnEmptyOthersList() async {
    let products = makeCategoryProducts(
        topRatedIDs: [9, 2, 5],
        otherIDs: []
    )
    let repository = FakeCategoryProductRepository(outcomes: [.success(products)])
    let viewModel = makeCategoryViewModel(
        name: "electronics",
        repository: repository
    )

    await viewModel.load()

    #expect(viewModel.content == .loaded(products))
    #expect(products.topRated.map(\.id) == [9, 2, 5])
    #expect(products.others.isEmpty)
    #expect(!CategoryDisplay.isEmpty(products))
}

@Test
@MainActor
func bothEmptyProductListsProduceTheEmptyDisplayState() async {
    let products = makeCategoryProducts(topRatedIDs: [], otherIDs: [])
    let repository = FakeCategoryProductRepository(outcomes: [.success(products)])
    let viewModel = makeCategoryViewModel(
        name: "electronics",
        repository: repository
    )

    await viewModel.load()

    #expect(viewModel.content == .loaded(products))
    #expect(CategoryDisplay.isEmpty(products))
}

@Test
@MainActor
func notFoundUsesTheCategoryUnavailableMessage() async {
    let repository = FakeCategoryProductRepository(
        outcomes: [.failure(.app(.notFound))]
    )
    let viewModel = makeCategoryViewModel(
        name: "removed category",
        repository: repository
    )

    await viewModel.load()

    #expect(viewModel.content == .failed(.notFound))
    #expect(
        CategoryDisplay.errorMessage(for: .notFound)
            == "This category is no longer available."
    )
}

@Test
@MainActor
func unreachableUsesTheBackendUnavailableMessage() async {
    let repository = FakeCategoryProductRepository(
        outcomes: [.failure(.app(.unreachable))]
    )
    let viewModel = makeCategoryViewModel(
        name: "electronics",
        repository: repository
    )

    await viewModel.load()

    #expect(viewModel.content == .failed(.unreachable))
    #expect(
        CategoryDisplay.errorMessage(for: .unreachable)
            == "Unable to connect. The backend may not be running."
    )
}

@Test
@MainActor
func retryReloadsAFailedCategoryAndRecovers() async {
    let products = makeCategoryProducts(
        topRatedIDs: [2, 7, 4],
        otherIDs: [1]
    )
    let repository = FakeCategoryProductRepository(
        outcomes: [
            .failure(.app(.unreachable)),
            .success(products),
        ]
    )
    let viewModel = makeCategoryViewModel(
        name: "men's clothing",
        repository: repository
    )

    await viewModel.load()
    #expect(viewModel.content == .failed(.unreachable))

    await viewModel.retry()

    #expect(viewModel.content == .loaded(products))
    #expect(await repository.requestCount() == 2)
    #expect(
        await repository.requestedCategoryNames()
            == ["men's clothing", "men's clothing"]
    )
}

@Test
@MainActor
func categoryLoadDoesNotDuplicateAnInFlightRequest() async {
    let products = makeCategoryProducts(
        topRatedIDs: [3, 8, 1],
        otherIDs: [2]
    )
    let repository = FakeCategoryProductRepository(
        outcomes: [.success(products)],
        holdFirstRequest: true
    )
    let viewModel = makeCategoryViewModel(
        name: "electronics",
        repository: repository
    )
    let loadTask = Task {
        await viewModel.load()
    }

    await repository.waitForRequest()
    await viewModel.load()
    let requestCount = await repository.requestCount()
    let released = await repository.releaseHeldRequest()
    await loadTask.value

    #expect(viewModel.content == .loaded(products))
    #expect(viewModel.content.isLoading == false)
    #expect(requestCount == 1)
    #expect(released)
}

@Test
@MainActor
func cancellationDoesNotSetFailedState() async {
    let repository = FakeCategoryProductRepository(
        outcomes: [.failure(.cancellation)]
    )
    let viewModel = makeCategoryViewModel(
        name: "electronics",
        repository: repository
    )

    await viewModel.load()

    #expect(viewModel.content == .idle)
}

@Test
@MainActor
func nonAppErrorsBecomeUnexpected() async {
    let repository = FakeCategoryProductRepository(
        outcomes: [.failure(.unexpected)]
    )
    let viewModel = makeCategoryViewModel(
        name: "electronics",
        repository: repository
    )

    await viewModel.load()

    #expect(viewModel.content == .failed(.unexpected))
}

@MainActor
private func makeCategoryViewModel(
    name: String,
    repository: FakeCategoryProductRepository
) -> CategoryViewModel {
    CategoryViewModel(
        categoryName: name,
        getCategoryProducts: GetCategoryProductsUseCase(repository: repository)
    )
}

private func makeCategoryProducts(
    category: String = "men's clothing",
    topRatedIDs: [Int],
    otherIDs: [Int]
) -> CategoryProducts {
    CategoryProducts(
        category: category,
        topRated: topRatedIDs.map(makeProduct),
        others: otherIDs.map(makeProduct)
    )
}

private func makeProduct(_ id: Int) -> Product {
    Product(
        id: id,
        title: "Product \(id)",
        description: "Sample description.",
        category: "men's clothing",
        price: Money(amount: Decimal(id * 10), currencyCode: "USD"),
        rating: Rating(rate: 4.5, count: 20 + id)
    )
}

private enum FakeCategoryFailure: Sendable {
    case app(AppError)
    case unexpected
    case cancellation
}

private enum FakeCategoryOutcome: Sendable {
    case success(CategoryProducts)
    case failure(FakeCategoryFailure)

    func get() throws -> CategoryProducts {
        switch self {
        case .success(let products):
            products
        case .failure(.app(let error)):
            throw error
        case .failure(.unexpected):
            throw UnexpectedCategoryError()
        case .failure(.cancellation):
            throw CancellationError()
        }
    }
}

private struct UnexpectedCategoryError: Error, Sendable {}

private actor FakeCategoryProductRepository: ProductRepository {
    private var outcomes: [FakeCategoryOutcome]
    private var outcomeIndex = 0
    private var holdFirstRequest: Bool
    private var heldContinuation: CheckedContinuation<CategoryProducts, any Error>?
    private var heldOutcome: FakeCategoryOutcome?
    private var requestWaiters: [CheckedContinuation<Void, Never>] = []
    private var categoryNames: [String] = []
    private(set) var requests = 0

    init(
        outcomes: [FakeCategoryOutcome] = [
            .success(CategoryProducts(category: "", topRated: [], others: [])),
        ],
        holdFirstRequest: Bool = false
    ) {
        self.outcomes = outcomes.isEmpty
            ? [.success(CategoryProducts(category: "", topRated: [], others: []))]
            : outcomes
        self.holdFirstRequest = holdFirstRequest
    }

    func featured() async throws -> [Product] {
        []
    }

    func categories() async throws -> [String] {
        []
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        requests += 1
        categoryNames.append(name)
        let waiters = requestWaiters
        requestWaiters.removeAll()
        waiters.forEach { $0.resume() }

        let outcome = nextOutcome()
        guard holdFirstRequest else {
            return try outcome.get()
        }
        holdFirstRequest = false

        return try await withCheckedThrowingContinuation { continuation in
            heldContinuation = continuation
            heldOutcome = outcome
        }
    }

    func search(query: String) async throws -> [Product] {
        []
    }

    func product(id: Int) async throws -> Product {
        throw AppError.notFound
    }

    func waitForRequest() async {
        guard requests == 0 else {
            return
        }
        await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func releaseHeldRequest() -> Bool {
        guard let continuation = heldContinuation, let outcome = heldOutcome else {
            return false
        }
        heldContinuation = nil
        heldOutcome = nil
        do {
            continuation.resume(returning: try outcome.get())
        } catch {
            continuation.resume(throwing: error)
        }
        return true
    }

    func requestCount() -> Int {
        requests
    }

    func requestedCategoryNames() -> [String] {
        categoryNames
    }

    private func nextOutcome() -> FakeCategoryOutcome {
        let index = min(outcomeIndex, outcomes.count - 1)
        outcomeIndex += 1
        return outcomes[index]
    }
}
