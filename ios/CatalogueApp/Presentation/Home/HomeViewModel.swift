import CatalogueDomain
import Observation

@Observable
@MainActor
final class HomeViewModel {
    private(set) var featured: LoadState<[Product]> = .idle
    private(set) var categories: LoadState<[String]> = .idle
    var searchText = ""

    private let getFeaturedProducts: GetFeaturedProductsUseCase
    private let getCategories: GetCategoriesUseCase

    init(
        getFeaturedProducts: GetFeaturedProductsUseCase,
        getCategories: GetCategoriesUseCase
    ) {
        self.getFeaturedProducts = getFeaturedProducts
        self.getCategories = getCategories
    }

    var canSearch: Bool {
        (try? SearchQuery(searchText)) != nil
    }

    func load() async {
        await loadSections(
            featured: isIdle(featured),
            categories: isIdle(categories)
        )
    }

    func retry() async {
        await loadSections(
            featured: isFailed(featured),
            categories: isFailed(categories)
        )
    }

    func refresh() async {
        await loadSections(featured: true, categories: true)
    }

    func submitSearch() -> String? {
        guard let query = try? SearchQuery(searchText) else {
            return nil
        }
        return query.value
    }

    private func loadSections(featured shouldLoadFeatured: Bool, categories shouldLoadCategories: Bool) async {
        let loadFeatured = shouldLoadFeatured && !featured.isLoading
        let loadCategories = shouldLoadCategories && !categories.isLoading
        guard loadFeatured || loadCategories else {
            return
        }

        let previousFeatured = featured
        let previousCategories = categories
        if loadFeatured {
            featured = .loading
        }
        if loadCategories {
            categories = .loading
        }

        async let featuredRequest = loadFeaturedProducts(
            shouldLoad: loadFeatured,
            previousState: previousFeatured
        )
        async let categoriesRequest = loadCategoryNames(
            shouldLoad: loadCategories,
            previousState: previousCategories
        )
        await featuredRequest
        await categoriesRequest
    }

    private func loadFeaturedProducts(
        shouldLoad: Bool,
        previousState: LoadState<[Product]>
    ) async {
        guard shouldLoad else {
            return
        }

        do {
            featured = .loaded(try await getFeaturedProducts.execute())
        } catch {
            if error is CancellationError {
                featured = previousState
            } else if let appError = error as? AppError {
                featured = .failed(appError)
            } else {
                featured = .failed(.unexpected)
            }
        }
    }

    private func loadCategoryNames(
        shouldLoad: Bool,
        previousState: LoadState<[String]>
    ) async {
        guard shouldLoad else {
            return
        }

        do {
            categories = .loaded(try await getCategories.execute())
        } catch {
            if error is CancellationError {
                categories = previousState
            } else if let appError = error as? AppError {
                categories = .failed(appError)
            } else {
                categories = .failed(.unexpected)
            }
        }
    }

    private func isIdle<Value>(_ state: LoadState<Value>) -> Bool {
        if case .idle = state {
            true
        } else {
            false
        }
    }

    private func isFailed<Value>(_ state: LoadState<Value>) -> Bool {
        if case .failed = state {
            true
        } else {
            false
        }
    }
}
