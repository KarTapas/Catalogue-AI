import CatalogueDomain
import Foundation
import Testing
@testable import CatalogueApp

@Test
@MainActor
func homeViewModelStartsIdle() {
    let viewModel = makeViewModel(repository: FakeProductRepository())

    #expect(viewModel.featured == .idle)
    #expect(viewModel.categories == .idle)
    #expect(viewModel.searchText.isEmpty)
}

@Test
@MainActor
func loadPublishesBothSectionsAndDoesNotReloadLoadedValues() async {
    let products = [makeProduct(id: 1), makeProduct(id: 2)]
    let categories = ["electronics", "men's clothing"]
    let repository = FakeProductRepository(
        featuredOutcome: .success(products),
        categoriesOutcome: .success(categories)
    )
    let viewModel = makeViewModel(repository: repository)

    await viewModel.load()
    await viewModel.load()

    #expect(viewModel.featured == .loaded(products))
    #expect(viewModel.categories == .loaded(categories))
    let counts = await repository.callCounts()
    #expect(counts.featured == 1)
    #expect(counts.categories == 1)
}

@Test
@MainActor
func featuredFailureDoesNotHideLoadedCategories() async {
    let categories = ["electronics"]
    let repository = FakeProductRepository(
        featuredOutcome: .failure(.app(.unreachable)),
        categoriesOutcome: .success(categories)
    )
    let viewModel = makeViewModel(repository: repository)

    await viewModel.load()

    #expect(viewModel.featured == .failed(.unreachable))
    #expect(viewModel.categories == .loaded(categories))
}

@Test
@MainActor
func categoriesFailureDoesNotHideLoadedFeaturedProducts() async {
    let products = [makeProduct(id: 3)]
    let repository = FakeProductRepository(
        featuredOutcome: .success(products),
        categoriesOutcome: .failure(.app(.serverUnavailable))
    )
    let viewModel = makeViewModel(repository: repository)

    await viewModel.load()

    #expect(viewModel.featured == .loaded(products))
    #expect(viewModel.categories == .failed(.serverUnavailable))
}

@Test
@MainActor
func appErrorsArePreservedAndUnexpectedErrorsAreMapped() async {
    let appErrorRepository = FakeProductRepository(
        featuredOutcome: .failure(.app(.rateLimited)),
        categoriesOutcome: .success([])
    )
    let appErrorViewModel = makeViewModel(repository: appErrorRepository)
    await appErrorViewModel.load()
    #expect(appErrorViewModel.featured == .failed(.rateLimited))

    let unexpectedRepository = FakeProductRepository(
        featuredOutcome: .failure(.unexpected),
        categoriesOutcome: .success([])
    )
    let unexpectedViewModel = makeViewModel(repository: unexpectedRepository)
    await unexpectedViewModel.load()
    #expect(unexpectedViewModel.featured == .failed(.unexpected))
}

@Test
@MainActor
func retryReloadsOnlyTheFailedSection() async {
    let products = [makeProduct(id: 4)]
    let repository = FakeProductRepository(
        featuredOutcome: .failure(.app(.unreachable)),
        categoriesOutcome: .success(["jewelery"])
    )
    let viewModel = makeViewModel(repository: repository)

    await viewModel.load()
    await repository.setFeaturedOutcome(.success(products))
    await viewModel.retry()

    #expect(viewModel.featured == .loaded(products))
    #expect(viewModel.categories == .loaded(["jewelery"]))
    let counts = await repository.callCounts()
    #expect(counts.featured == 2)
    #expect(counts.categories == 1)
}

@Test
@MainActor
func loadDoesNotDuplicateAnInFlightRequest() async {
    let products = [makeProduct(id: 5)]
    let repository = FakeProductRepository(
        featuredOutcome: .success(products),
        categoriesOutcome: .success(["electronics"]),
        holdFeaturedRequest: true
    )
    let viewModel = makeViewModel(repository: repository)
    let loadTask = Task {
        await viewModel.load()
    }

    await repository.waitForFeaturedRequest()
    await viewModel.load()
    #expect(viewModel.featured.isLoading)
    let counts = await repository.callCounts()

    await repository.releaseFeaturedRequest()
    await loadTask.value

    #expect(counts.featured == 1)
    #expect(counts.categories == 1)
    #expect(viewModel.featured == .loaded(products))
}

@Test
@MainActor
func cancellationRestoresThePreviousStateInsteadOfFailing() async {
    let repository = FakeProductRepository(
        featuredOutcome: .failure(.cancellation),
        categoriesOutcome: .success(["electronics"])
    )
    let viewModel = makeViewModel(repository: repository)

    await viewModel.load()

    #expect(viewModel.featured == .idle)
    #expect(viewModel.categories == .loaded(["electronics"]))
}

@Test
@MainActor
func refreshReloadsBothSections() async {
    let repository = FakeProductRepository(
        featuredOutcome: .success([makeProduct(id: 6)]),
        categoriesOutcome: .success(["electronics"])
    )
    let viewModel = makeViewModel(repository: repository)

    await viewModel.load()
    await repository.setFeaturedOutcome(
        .success([makeProduct(id: 12), makeProduct(id: 7)])
    )
    await repository.setCategoriesOutcome(
        .success(["women's clothing", "jewelery"])
    )
    await viewModel.refresh()

    guard case let .loaded(featuredProducts) = viewModel.featured else {
        Issue.record("Expected refreshed featured products to be loaded")
        return
    }
    #expect(featuredProducts.map(\.id) == [12, 7])
    #expect(featuredProducts.map(\.title) == ["Product 12", "Product 7"])

    guard case let .loaded(categories) = viewModel.categories else {
        Issue.record("Expected refreshed categories to be loaded")
        return
    }
    #expect(categories == ["women's clothing", "jewelery"])

    let counts = await repository.callCounts()
    #expect(counts.featured == 2)
    #expect(counts.categories == 2)
}

@Test
@MainActor
func canSearchUsesTrimmedSearchQueryBounds() {
    let viewModel = makeViewModel(repository: FakeProductRepository())

    for query in ["", " ", "a", String(repeating: "x", count: 101)] {
        viewModel.searchText = query
        #expect(!viewModel.canSearch)
    }

    viewModel.searchText = "jacket"
    #expect(viewModel.canSearch)
}

@Test
@MainActor
func submitSearchTrimsAndNeverTouchesARepository() async {
    let repository = FakeProductRepository()
    let viewModel = makeViewModel(repository: repository)
    viewModel.searchText = "  jacket \n"

    #expect(viewModel.submitSearch() == "jacket")
    viewModel.searchText = "a"
    #expect(viewModel.submitSearch() == nil)

    let counts = await repository.callCounts()
    #expect(counts.featured == 0)
    #expect(counts.categories == 0)
    #expect(counts.search == 0)
}

@Test
func categoryCapitalizationIsDisplayOnly() {
    let category = "men's clothing"

    #expect(category.capitalizedWordsForDisplay() == "Men's Clothing")
    #expect(category == "men's clothing")
}

@MainActor
private func makeViewModel(repository: FakeProductRepository) -> HomeViewModel {
    HomeViewModel(
        getFeaturedProducts: GetFeaturedProductsUseCase(repository: repository),
        getCategories: GetCategoriesUseCase(repository: repository)
    )
}

private func makeProduct(id: Int) -> Product {
    Product(
        id: id,
        title: "Product \(id)",
        description: "Sample description.",
        category: "electronics",
        price: Money(amount: Decimal(id), currencyCode: "USD"),
        rating: Rating(rate: 4.5, count: 20)
    )
}

private struct CallCounts: Equatable, Sendable {
    let featured: Int
    let categories: Int
    let search: Int
}

private enum FakeRepositoryFailure: Error, Sendable {
    case app(AppError)
    case unexpected
    case cancellation
}

private enum FakeRepositoryOutcome<Value: Sendable>: Sendable {
    case success(Value)
    case failure(FakeRepositoryFailure)

    func get() throws -> Value {
        switch self {
        case .success(let value):
            value
        case .failure(.app(let error)):
            throw error
        case .failure(.unexpected):
            throw UnexpectedRepositoryError()
        case .failure(.cancellation):
            throw CancellationError()
        }
    }
}

private struct UnexpectedRepositoryError: Error, Sendable {}

private actor FakeProductRepository: ProductRepository {
    private var featuredOutcome: FakeRepositoryOutcome<[Product]>
    private var categoriesOutcome: FakeRepositoryOutcome<[String]>
    private var holdFeaturedRequest: Bool
    private var featuredContinuation: CheckedContinuation<[Product], any Error>?
    private var featuredStartedWaiters: [CheckedContinuation<Void, Never>] = []

    private(set) var featuredCalls = 0
    private(set) var categoriesCalls = 0
    private(set) var searchCalls = 0

    init(
        featuredOutcome: FakeRepositoryOutcome<[Product]> = .success([]),
        categoriesOutcome: FakeRepositoryOutcome<[String]> = .success([]),
        holdFeaturedRequest: Bool = false
    ) {
        self.featuredOutcome = featuredOutcome
        self.categoriesOutcome = categoriesOutcome
        self.holdFeaturedRequest = holdFeaturedRequest
    }

    func featured() async throws -> [Product] {
        featuredCalls += 1
        guard holdFeaturedRequest else {
            return try featuredOutcome.get()
        }

        return try await withCheckedThrowingContinuation { continuation in
            featuredContinuation = continuation
            let waiters = featuredStartedWaiters
            featuredStartedWaiters.removeAll()
            waiters.forEach { $0.resume() }
        }
    }

    func categories() async throws -> [String] {
        categoriesCalls += 1
        return try categoriesOutcome.get()
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        let products = try featuredOutcome.get()
        return CategoryProducts(
            category: name,
            topRated: Array(products.prefix(3)),
            others: Array(products.dropFirst(3))
        )
    }

    func search(query: String) async throws -> [Product] {
        searchCalls += 1
        return try featuredOutcome.get()
    }

    func product(id: Int) async throws -> Product {
        guard let product = try featuredOutcome.get().first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return product
    }

    func setFeaturedOutcome(_ outcome: FakeRepositoryOutcome<[Product]>) {
        featuredOutcome = outcome
    }

    func setCategoriesOutcome(_ outcome: FakeRepositoryOutcome<[String]>) {
        categoriesOutcome = outcome
    }

    func waitForFeaturedRequest() async {
        guard featuredCalls == 0 else {
            return
        }
        await withCheckedContinuation { continuation in
            featuredStartedWaiters.append(continuation)
        }
    }

    func releaseFeaturedRequest() {
        holdFeaturedRequest = false
        guard let continuation = featuredContinuation else {
            return
        }
        featuredContinuation = nil
        do {
            continuation.resume(returning: try featuredOutcome.get())
        } catch {
            continuation.resume(throwing: error)
        }
    }

    func callCounts() -> CallCounts {
        CallCounts(
            featured: featuredCalls,
            categories: categoriesCalls,
            search: searchCalls
        )
    }
}
