import CatalogueDomain
import Observation

@Observable
@MainActor
final class CategoryViewModel {
    let categoryName: String
    private(set) var content: LoadState<CategoryProducts> = .idle

    private let getCategoryProducts: GetCategoryProductsUseCase

    init(categoryName: String, getCategoryProducts: GetCategoryProductsUseCase) {
        self.categoryName = categoryName
        self.getCategoryProducts = getCategoryProducts
    }

    var displayTitle: String {
        categoryName.capitalizedWordsForDisplay()
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

    private func fetch() async {
        guard !content.isLoading else {
            return
        }

        let previousState = content
        content = .loading

        do {
            content = .loaded(try await getCategoryProducts.execute(name: categoryName))
        } catch is CancellationError {
            content = previousState
        } catch let error as AppError {
            content = .failed(error)
        } catch {
            content = .failed(.unexpected)
        }
    }
}

enum CategoryDisplay {
    static func isEmpty(_ products: CategoryProducts) -> Bool {
        products.topRated.isEmpty && products.others.isEmpty
    }

    static func errorMessage(for error: AppError) -> String {
        if case .notFound = error {
            return "This category is no longer available."
        }
        return error.message
    }
}
