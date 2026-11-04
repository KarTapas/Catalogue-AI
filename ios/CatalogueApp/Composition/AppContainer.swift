import CatalogueData
import CatalogueDomain

struct AppContainer {
    let getFeaturedProducts: GetFeaturedProductsUseCase
    let getCategories: GetCategoriesUseCase
    let getCategoryProducts: GetCategoryProductsUseCase
    let searchProducts: SearchProductsUseCase
    let getProduct: GetProductUseCase
    let submitEnquiry: SubmitEnquiryUseCase

    init(configuration: AppConfig) {
        let apiConfiguration = APIConfiguration(baseURL: configuration.apiBaseURL)
        let transport = URLSessionTransport()
        let apiClient = APIClient(
            configuration: apiConfiguration,
            transport: transport
        )
        let productRepository = RemoteProductRepository(apiClient: apiClient)
        let enquiryRepository = RemoteEnquiryRepository(apiClient: apiClient)

        self.init(
            productRepository: productRepository,
            enquiryRepository: enquiryRepository
        )
    }

    init(
        productRepository: any ProductRepository,
        enquiryRepository: any EnquiryRepository
    ) {
        getFeaturedProducts = GetFeaturedProductsUseCase(repository: productRepository)
        getCategories = GetCategoriesUseCase(repository: productRepository)
        getCategoryProducts = GetCategoryProductsUseCase(repository: productRepository)
        searchProducts = SearchProductsUseCase(repository: productRepository)
        getProduct = GetProductUseCase(repository: productRepository)
        submitEnquiry = SubmitEnquiryUseCase(repository: enquiryRepository)
    }
}
