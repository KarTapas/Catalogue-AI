import CatalogueDomain
import SwiftUI

enum Route: Hashable {
    case category(String)
    case product(Int)
    case search(String)
    #if DEBUG
    case enquiry(Int, EnquiryPreviewMode)
    #endif
}

struct RootView: View {
    @State private var path: [Route]
    @State private var viewModel: HomeViewModel
    private let getCategoryProducts: GetCategoryProductsUseCase
    private let searchProducts: SearchProductsUseCase
    private let getProduct: GetProductUseCase
    private let submitEnquiry: SubmitEnquiryUseCase

    init(container: AppContainer, initialRoute: Route? = nil) {
        _path = State(initialValue: initialRoute.map { [$0] } ?? [])
        _viewModel = State(
            initialValue: HomeViewModel(
                getFeaturedProducts: container.getFeaturedProducts,
                getCategories: container.getCategories
            )
        )
        getCategoryProducts = container.getCategoryProducts
        searchProducts = container.searchProducts
        getProduct = container.getProduct
        submitEnquiry = container.submitEnquiry
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(viewModel: viewModel, path: $path)
                .navigationTitle("Catalogue")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(let name):
                        CategoryView(
                            viewModel: CategoryViewModel(
                                categoryName: name,
                                getCategoryProducts: getCategoryProducts
                            ),
                            path: $path
                        )
                    case .product(let id):
                        ProductDetailView(
                            viewModel: ProductDetailViewModel(
                                productID: id,
                                getProduct: getProduct
                            ),
                            submitEnquiry: submitEnquiry
                        )
                    #if DEBUG
                    case .enquiry(let id, let mode):
                        ProductDetailView(
                            viewModel: ProductDetailViewModel(
                                productID: id,
                                getProduct: getProduct
                            ),
                            submitEnquiry: submitEnquiry,
                            debugPreviewMode: mode
                        )
                    #endif
                    case .search(let query):
                        SearchResultsView(
                            viewModel: SearchResultsViewModel(
                                initialQuery: query,
                                searchProducts: searchProducts
                            ),
                            path: $path
                        )
                    }
                }
        }
        .tint(Palette.brand)
    }
}
