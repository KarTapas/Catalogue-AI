import CatalogueDomain
import Foundation
import Observation

@Observable
@MainActor
final class SearchResultsViewModel {
    var searchText: String {
        didSet {
            if canSearch {
                validationMessage = nil
            }
        }
    }

    private(set) var submittedQuery: String?
    private(set) var results: LoadState<[Product]> = .idle
    private(set) var validationMessage: String?

    private let searchProducts: SearchProductsUseCase

    @ObservationIgnored private var currentSearchTask: Task<[Product], any Error>?
    @ObservationIgnored private var currentRequestID = 0

    init(initialQuery: String, searchProducts: SearchProductsUseCase) {
        searchText = initialQuery
        self.searchProducts = searchProducts
    }

    var canSearch: Bool {
        (try? SearchQuery(searchText)) != nil
    }

    var resultSummary: String? {
        guard
            case .loaded(let products) = results,
            let submittedQuery
        else {
            return nil
        }
        return SearchResultsText.summary(count: products.count, query: submittedQuery)
    }

    var emptyMessage: String {
        SearchResultsText.emptyMessage(query: submittedQuery ?? searchText)
    }

    func start() async {
        guard case .idle = results else {
            return
        }
        await search()
    }

    func search() async {
        guard let query = try? SearchQuery(searchText) else {
            validationMessage = SearchResultsText.localValidationMessage(for: searchText)
            return
        }

        validationMessage = nil
        guard !isAlreadyLoadingOrLoaded(query: query.value) else {
            return
        }
        await execute(query: query.value)
    }

    func retry() async {
        guard
            case .failed = results,
            let submittedQuery
        else {
            return
        }
        await execute(query: submittedQuery)
    }

    private func execute(query: String) async {
        let previousResults = results
        let previousSubmittedQuery = submittedQuery
        let previousValidationMessage = validationMessage

        currentSearchTask?.cancel()
        currentRequestID &+= 1
        let requestID = currentRequestID

        submittedQuery = query
        validationMessage = nil
        results = .loading

        let request = Task<[Product], any Error> {
            try await searchProducts.execute(query: query)
        }
        currentSearchTask = request

        do {
            let products = try await withTaskCancellationHandler {
                try await request.value
            } onCancel: {
                request.cancel()
            }
            try Task.checkCancellation()
            guard currentRequestID == requestID else {
                return
            }
            currentSearchTask = nil
            results = .loaded(products)
        } catch {
            guard currentRequestID == requestID else {
                return
            }
            currentSearchTask = nil

            if error is CancellationError {
                results = previousResults
                submittedQuery = previousSubmittedQuery
                validationMessage = previousValidationMessage
            } else if let appError = error as? AppError {
                results = .failed(appError)
                validationMessage = SearchResultsText.validationMessage(for: appError)
            } else {
                results = .failed(.unexpected)
            }
        }
    }

    private func isAlreadyLoadingOrLoaded(query: String) -> Bool {
        if results.isLoading, submittedQuery == query {
            return true
        }
        if case .loaded = results, submittedQuery == query {
            return true
        }
        return false
    }
}

enum SearchResultsText {
    static func summary(count: Int, query: String) -> String {
        let noun = count == 1 ? "result" : "results"
        return "\(count) \(noun) for “\(query)”"
    }

    static func emptyMessage(query: String) -> String {
        "No results for “\(query)”"
    }

    static func localValidationMessage(for query: String) -> String {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.count < 2 {
            return "Enter at least 2 characters."
        }
        return "Enter no more than 100 characters."
    }

    static func validationMessage(for error: AppError) -> String? {
        guard case .validation(let fields) = error else {
            return nil
        }
        let message = fields.keys.sorted().compactMap { fields[$0] }.first
        return message.flatMap { $0.isEmpty ? nil : $0 } ?? "Enter a valid search term."
    }

    static func errorMessage(for error: AppError) -> String {
        validationMessage(for: error) ?? error.message
    }
}
