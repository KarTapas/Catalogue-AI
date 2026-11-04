import CatalogueDomain
import Foundation

enum DesignPreviewData {
    static let product = Product(
        id: 1,
        title: "Everyday Canvas Backpack",
        description: "A lightweight backpack for daily use.",
        category: "Accessories",
        price: Money(
            amount: Decimal(string: "39.95", locale: Locale(identifier: "en_US_POSIX"))
                ?? .zero,
            currencyCode: "USD"
        ),
        rating: Rating(rate: 4.7, count: 128)
    )
}
