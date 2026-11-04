import CatalogueDomain
import Foundation
import Testing
@testable import CatalogueApp

@Test @MainActor
func searchResultsViewModelStartsIdleWithInitialSearchText() async {
    let repository = FakeSearchRepository(outcomes: [])
    let viewModel = makeSearchViewModel(initialQuery: "  jacket  ", repository: repository)

    #expect(viewModel.searchText == "  jacket  ")
    #expect(viewModel.submittedQuery == nil)
    #expect(viewModel.results == .idle)
    let queries = await repository.recordedQueries()
    #expect(queries.isEmpty)
}

@Test @MainActor
func searchTrimsTheQueryAndPublishesProductsInBackendOrder() async {
    let products = [makeProduct(id: 3), makeProduct(id: 1), makeProduct(id: 2)]
    let repository = FakeSearchRepository(
        outcomes: [.success(products)],
        heldSearchCalls: [1]
    )
    let viewModel = makeSearchViewModel(initialQuery: "jacket", repository: repository)
    viewModel.searchText = "  jacket \n"

    #expect(viewModel.results == .idle)
    let searchTask = Task {
        await viewModel.search()
    }
    await repository.waitForSearchCount(1)
    #expect(viewModel.results == .loading)

    let queriesWhileLoading = await repository.recordedQueries()
    #expect(queriesWhileLoading == ["jacket"])

    await repository.completeSearch(1)
    await searchTask.value

    #expect(viewModel.submittedQuery == "jacket")
    #expect(viewModel.results == .loaded(products))
    #expect(viewModel.results.value?.map(\.id) == [3, 1, 2])
}

@Test @MainActor
func invalidTextKeepsPreviousResultsAndDoesNotCallTheUseCase() async {
    let products = [makeProduct(id: 7)]
    let repository = FakeSearchRepository(outcomes: [.success(products)])
    let viewModel = makeSearchViewModel(initialQuery: "boots", repository: repository)
    await viewModel.search()
    let previousResults = viewModel.results

    let invalidInputs = [
        ("", "Enter at least 2 characters."),
        (" ", "Enter at least 2 characters."),
        ("a", "Enter at least 2 characters."),
        (String(repeating: "x", count: 101), "Enter no more than 100 characters.")
    ]

    for (input, message) in invalidInputs {
        viewModel.searchText = input
        await viewModel.search()
        #expect(viewModel.results == previousResults)
        #expect(viewModel.validationMessage == message)
    }

    let queries = await repository.recordedQueries()
    #expect(queries == ["boots"])
}

@Test @MainActor
func validationMessageClearsWhenTextBecomesValid() async {
    let repository = FakeSearchRepository(outcomes: [])
    let viewModel = makeSearchViewModel(initialQuery: "a", repository: repository)

    await viewModel.search()
    #expect(viewModel.validationMessage == "Enter at least 2 characters.")
    #expect(viewModel.results == .idle)

    viewModel.searchText = "jacket"

    #expect(viewModel.validationMessage == nil)
    #expect(viewModel.results == .idle)
    let queries = await repository.recordedQueries()
    #expect(queries.isEmpty)
}

@Test @MainActor
func zeroResultsRemainLoadedAndShowTheEmptyMessage() async {
    let repository = FakeSearchRepository(outcomes: [.success([])])
    let viewModel = makeSearchViewModel(initialQuery: "zzzzqq", repository: repository)

    await viewModel.search()

    #expect(viewModel.results == .loaded([]))
    #expect(viewModel.resultSummary == "0 results for “zzzzqq”")
    #expect(viewModel.emptyMessage == "No results for “zzzzqq”")
}

@Test @MainActor
func appErrorsArePreservedInTheFailedState() async {
    let error = AppError.rateLimited
    let repository = FakeSearchRepository(outcomes: [.failure(error)])
    let viewModel = makeSearchViewModel(initialQuery: "jacket", repository: repository)

    await viewModel.search()

    #expect(viewModel.results == .failed(error))
}

@Test @MainActor
func searchNonAppErrorsBecomeUnexpected() async {
    let repository = FakeSearchRepository(outcomes: [.unexpectedFailure])
    let viewModel = makeSearchViewModel(initialQuery: "jacket", repository: repository)

    await viewModel.search()

    #expect(viewModel.results == .failed(.unexpected))
}

@Test @MainActor
func serverValidationErrorsShowTheirValidationMessage() async {
    let message = "Search query must be between 2 and 100 characters."
    let error = AppError.validation(fields: ["q": message])
    let repository = FakeSearchRepository(outcomes: [.failure(error)])
    let viewModel = makeSearchViewModel(initialQuery: "jacket", repository: repository)

    await viewModel.search()

    #expect(viewModel.results == .failed(error))
    #expect(viewModel.validationMessage == message)
    #expect(SearchResultsText.errorMessage(for: error) == message)
}

@Test @MainActor
func latestSubmitWinsWhenAnOlderRequestReturnsLate() async {
    let oldProduct = makeProduct(id: 1)
    let newProduct = makeProduct(id: 2)
    let repository = FakeSearchRepository(
        outcomes: [.success([oldProduct]), .success([newProduct])],
        heldSearchCalls: [1]
    )
    let viewModel = makeSearchViewModel(initialQuery: "older", repository: repository)

    let firstSearch = Task {
        await viewModel.search()
    }
    await repository.waitForSearchCount(1)
    #expect(viewModel.results == .loading)

    viewModel.searchText = "newer"
    let secondSearch = Task {
        await viewModel.search()
    }
    await secondSearch.value
    #expect(viewModel.results == .loaded([newProduct]))

    let queries = await repository.recordedQueries()
    #expect(queries == ["older", "newer"])

    await repository.completeSearch(1)
    await firstSearch.value

    #expect(viewModel.results == .loaded([newProduct]))
    #expect(viewModel.results != .loaded([oldProduct]))
}

@Test @MainActor
func startDoesNotDuplicateInFlightOrLoadedSearches() async {
    let products = [makeProduct(id: 1)]
    let repository = FakeSearchRepository(
        outcomes: [.success(products)],
        heldSearchCalls: [1]
    )
    let viewModel = makeSearchViewModel(initialQuery: "jacket", repository: repository)

    let firstStart = Task {
        await viewModel.start()
    }
    await repository.waitForSearchCount(1)
    let secondStart = Task {
        await viewModel.start()
    }
    await secondStart.value

    let queriesWhileLoading = await repository.recordedQueries()
    #expect(queriesWhileLoading == ["jacket"])
    #expect(viewModel.results == .loading)

    await repository.completeSearch(1)
    await firstStart.value
    await viewModel.start()

    #expect(viewModel.results == .loaded(products))
    let queriesAfterLoadedStart = await repository.recordedQueries()
    #expect(queriesAfterLoadedStart == ["jacket"])
}

@Test @MainActor
func searchCancellationRestoresPreviousStateInsteadOfFailing() async {
    let repository = FakeSearchRepository(outcomes: [.cancelled])
    let viewModel = makeSearchViewModel(initialQuery: "jacket", repository: repository)

    await viewModel.search()

    #expect(viewModel.results == .idle)
    #expect(viewModel.results.isLoading == false)
}

@Test @MainActor
func retryUsesTheLastSubmittedQueryRatherThanEditedText() async {
    let products = [makeProduct(id: 4)]
    let repository = FakeSearchRepository(
        outcomes: [.failure(.unreachable), .success(products)]
    )
    let viewModel = makeSearchViewModel(initialQuery: " boots ", repository: repository)
    await viewModel.search()

    #expect(viewModel.submittedQuery == "boots")
    #expect(viewModel.results == .failed(.unreachable))

    viewModel.searchText = "hats"
    await viewModel.retry()

    #expect(viewModel.results == .loaded(products))
    #expect(viewModel.submittedQuery == "boots")
    let queries = await repository.recordedQueries()
    #expect(queries == ["boots", "boots"])
}

@Test
func searchSummaryUsesCorrectSingularAndPluralText() {
    #expect(SearchResultsText.summary(count: 0, query: "jacket") == "0 results for “jacket”")
    #expect(SearchResultsText.summary(count: 1, query: "jacket") == "1 result for “jacket”")
    #expect(SearchResultsText.summary(count: 2, query: "jacket") == "2 results for “jacket”")
}

@Test
func productRouteMapsTheTappedProductToItsTypedDestination() {
    let product = makeProduct(id: 29)

    #expect(ProductRoute.route(for: product) == .product(29))
}

@MainActor
private func makeSearchViewModel(
    initialQuery: String,
    repository: any ProductRepository
) -> SearchResultsViewModel {
    SearchResultsViewModel(
        initialQuery: initialQuery,
        searchProducts: SearchProductsUseCase(repository: repository)
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

private enum SearchOutcome: Sendable {
    case success([Product])
    case failure(AppError)
    case unexpectedFailure
    case cancelled

    func get() throws -> [Product] {
        switch self {
        case .success(let products):
            products
        case .failure(let error):
            throw error
        case .unexpectedFailure:
            throw UnexpectedSearchError()
        case .cancelled:
            throw CancellationError()
        }
    }
}

private struct UnexpectedSearchError: Error, Sendable {}

private actor FakeSearchRepository: ProductRepository {
    private var outcomes: [SearchOutcome]
    private let heldSearchCalls: Set<Int>
    private var continuations: [Int: CheckedContinuation<[Product], any Error>] = [:]
    private var searchWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]
    private var queries: [String] = []

    init(outcomes: [SearchOutcome], heldSearchCalls: Set<Int> = []) {
        self.outcomes = outcomes
        self.heldSearchCalls = heldSearchCalls
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
        let callNumber = queries.count + 1
        queries.append(query)
        resumeSearchWaiters(upTo: callNumber)

        guard outcomes.indices.contains(callNumber - 1) else {
            throw AppError.unexpected
        }
        let outcome = outcomes[callNumber - 1]
        guard heldSearchCalls.contains(callNumber) else {
            return try outcome.get()
        }

        return try await withCheckedThrowingContinuation { continuation in
            continuations[callNumber] = continuation
        }
    }

    func product(id: Int) async throws -> Product {
        throw AppError.notFound
    }

    func waitForSearchCount(_ count: Int) async {
        guard queries.count < count else {
            return
        }
        await withCheckedContinuation { continuation in
            searchWaiters[count, default: []].append(continuation)
        }
    }

    func completeSearch(_ callNumber: Int) {
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

    func recordedQueries() -> [String] {
        queries
    }

    private func resumeSearchWaiters(upTo count: Int) {
        for expectedCount in searchWaiters.keys.filter({ $0 <= count }) {
            guard let waiters = searchWaiters.removeValue(forKey: expectedCount) else {
                continue
            }
            waiters.forEach { $0.resume() }
        }
    }
}
