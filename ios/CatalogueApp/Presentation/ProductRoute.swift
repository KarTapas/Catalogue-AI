import CatalogueDomain

enum ProductRoute {
    static func route(for product: Product) -> Route {
        .product(product.id)
    }
}
