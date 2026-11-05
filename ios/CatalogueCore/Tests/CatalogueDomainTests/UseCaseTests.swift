import Foundation
import CatalogueDomain
import Testing

@Test
func productUseCasesReturnRepositoryValues() async throws {
    let product = try makeProduct()
    let categoryProducts = CategoryProducts(
        category: "kitchen",
        topRated: [product],
        others: []
    )
    let repository = FakeProductRepository(
        featuredProducts: [product],
        categoryNames: ["kitchen"],
        categoryResult: categoryProducts,
        searchResults: [product],
        productResult: product
    )

    let featured = try await GetFeaturedProductsUseCase(repository: repository).execute()
    let categories = try await GetCategoriesUseCase(repository: repository).execute()
    let category = try await GetCategoryProductsUseCase(repository: repository)
        .execute(name: "kitchen")
    let search = try await SearchProductsUseCase(repository: repository)
        .execute(query: "tea")
    let fetchedProduct = try await GetProductUseCase(repository: repository)
        .execute(id: product.id)

    #expect(featured == [product])
    #expect(categories == ["kitchen"])
    #expect(category == categoryProducts)
    #expect(search == [product])
    #expect(fetchedProduct == product)
}

@Test
func searchUseCaseTrimsValidQueriesBeforeCallingTheRepository() async throws {
    let repository = FakeProductRepository()
    let result = try await SearchProductsUseCase(repository: repository)
        .execute(query: "  tea  ")
    let queries = await repository.recordedSearchQueries()

    #expect(result.isEmpty)
    #expect(queries == ["tea"])
}

@Test
func searchUseCaseRejectsShortQueriesWithoutCallingTheRepository() async {
    let repository = FakeProductRepository()
    let useCase = SearchProductsUseCase(repository: repository)

    let error = await captureError {
        try await useCase.execute(query: "a")
    }
    let queries = await repository.recordedSearchQueries()

    #expect(
        (error as? AppError) == .validation(
            fields: ["query": "Enter a search query between 2 and 100 characters."]
        )
    )
    #expect(queries.isEmpty)
}

@Test
func submitEnquiryUseCaseRejectsInvalidDataWithoutCallingTheRepository() async {
    let repository = FakeEnquiryRepository()
    let useCase = SubmitEnquiryUseCase(repository: repository)
    let invalidEnquiry = makeEnquiry(name: " ")

    let error = await captureError {
        try await useCase.execute(invalidEnquiry)
    }
    let submissions = await repository.recordedSubmissions()

    #expect((error as? AppError) == .validation(fields: ["name": "Enter your name."]))
    #expect(submissions.isEmpty)
}

@Test
func submitEnquiryUseCaseTrimsValuesBeforeSubmitting() async throws {
    let repository = FakeEnquiryRepository()
    let useCase = SubmitEnquiryUseCase(repository: repository)
    let enquiry = makeEnquiry(
        name: "  Ada Lovelace  ",
        email: "ada@example.test",
        phone: "  +1 555 010-1234  ",
        message: "  I have a question.  "
    )

    let receipt = try await useCase.execute(enquiry)
    let submissions = await repository.recordedSubmissions()

    #expect(receipt == EnquiryReceipt(id: "receipt-1"))
    #expect(submissions == [
        Enquiry(
            productId: 1,
            name: "Ada Lovelace",
            email: "ada@example.test",
            phone: "+1 555 010-1234",
            message: "I have a question."
        ),
    ])
}

@Test
func useCasesPropagateRepositoryErrorsUnchanged() async throws {
    let expectedError = AppError.serverUnavailable
    let product = try makeProduct()
    let categoryProducts = CategoryProducts(category: "kitchen", topRated: [product], others: [])
    let productRepository = FakeProductRepository(
        categoryResult: categoryProducts,
        productResult: product,
        failure: expectedError
    )
    let enquiryRepository = FakeEnquiryRepository(failure: expectedError)

    let featuredError = await captureError {
        try await GetFeaturedProductsUseCase(repository: productRepository).execute()
    }
    let categoriesError = await captureError {
        try await GetCategoriesUseCase(repository: productRepository).execute()
    }
    let categoryError = await captureError {
        try await GetCategoryProductsUseCase(repository: productRepository)
            .execute(name: "kitchen")
    }
    let searchError = await captureError {
        try await SearchProductsUseCase(repository: productRepository)
            .execute(query: "tea")
    }
    let productError = await captureError {
        try await GetProductUseCase(repository: productRepository).execute(id: product.id)
    }
    let enquiryError = await captureError {
        try await SubmitEnquiryUseCase(repository: enquiryRepository)
            .execute(makeEnquiry())
    }

    #expect((featuredError as? AppError) == expectedError)
    #expect((categoriesError as? AppError) == expectedError)
    #expect((categoryError as? AppError) == expectedError)
    #expect((searchError as? AppError) == expectedError)
    #expect((productError as? AppError) == expectedError)
    #expect((enquiryError as? AppError) == expectedError)
}

private actor FakeProductRepository: ProductRepository {
    private let featuredProducts: [Product]
    private let categoryNames: [String]
    private let categoryResult: CategoryProducts?
    private let searchResults: [Product]
    private let productResult: Product?
    private let failure: AppError?
    private var searchQueries: [String] = []

    init(
        featuredProducts: [Product] = [],
        categoryNames: [String] = [],
        categoryResult: CategoryProducts? = nil,
        searchResults: [Product] = [],
        productResult: Product? = nil,
        failure: AppError? = nil
    ) {
        self.featuredProducts = featuredProducts
        self.categoryNames = categoryNames
        self.categoryResult = categoryResult
        self.searchResults = searchResults
        self.productResult = productResult
        self.failure = failure
    }

    func featured() async throws -> [Product] {
        try throwFailureIfNeeded()
        return featuredProducts
    }

    func categories() async throws -> [String] {
        try throwFailureIfNeeded()
        return categoryNames
    }

    func categoryProducts(name: String) async throws -> CategoryProducts {
        try throwFailureIfNeeded()
        guard let categoryResult else {
            throw AppError.notFound
        }
        return categoryResult
    }

    func search(query: String) async throws -> [Product] {
        searchQueries.append(query)
        try throwFailureIfNeeded()
        return searchResults
    }

    func product(id: Int) async throws -> Product {
        try throwFailureIfNeeded()
        guard let productResult else {
            throw AppError.notFound
        }
        return productResult
    }

    func recordedSearchQueries() -> [String] {
        searchQueries
    }

    private func throwFailureIfNeeded() throws {
        if let failure {
            throw failure
        }
    }
}

private actor FakeEnquiryRepository: EnquiryRepository {
    private let receipt: EnquiryReceipt
    private let failure: AppError?
    private var submissions: [Enquiry] = []

    init(
        receipt: EnquiryReceipt = EnquiryReceipt(id: "receipt-1"),
        failure: AppError? = nil
    ) {
        self.receipt = receipt
        self.failure = failure
    }

    func submit(_ enquiry: Enquiry) async throws -> EnquiryReceipt {
        submissions.append(enquiry)
        if let failure {
            throw failure
        }
        return receipt
    }

    func recordedSubmissions() -> [Enquiry] {
        submissions
    }
}

private func makeProduct() throws -> Product {
    let amount = try #require(
        Decimal(string: "19.95", locale: Locale(identifier: "en_US_POSIX"))
    )
    return Product(
        id: 1,
        title: "Amber Kettle",
        description: "A brushed stainless steel electric kettle.",
        category: "kitchen",
        price: Money(amount: amount, currencyCode: "USD"),
        imageURL: nil,
        rating: Rating(rate: 4.8, count: 100)
    )
}

private func makeEnquiry(
    productId: Int = 1,
    name: String = "Ada Lovelace",
    email: String = "ada@example.test",
    phone: String? = nil,
    message: String = "I have a question."
) -> Enquiry {
    Enquiry(
        productId: productId,
        name: name,
        email: email,
        phone: phone,
        message: message
    )
}

private func captureError<T>(
    from operation: () async throws -> T
) async -> (any Error)? {
    do {
        _ = try await operation()
        return nil
    } catch {
        return error
    }
}
