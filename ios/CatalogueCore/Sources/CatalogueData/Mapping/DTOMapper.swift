import CatalogueDomain
import Foundation

enum DTOMapper {
    static func product(_ dto: ProductDTO) throws -> Product {
        guard let amount = Decimal(
            string: dto.price.amount,
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw AppError.unexpected
        }

        return Product(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            category: dto.category,
            price: Money(amount: amount, currencyCode: dto.price.currency),
            imageURL: imageURL(from: dto.imageUrl),
            rating: Rating(rate: dto.rating.rate, count: dto.rating.count)
        )
    }

    static func categoryProducts(_ dto: CategoryProductsDTO) throws -> CategoryProducts {
        CategoryProducts(
            category: dto.category,
            topRated: try dto.topRated.map(product),
            others: try dto.others.map(product)
        )
    }

    static func imageURL(from value: String?) -> URL? {
        guard
            let value,
            let components = URLComponents(string: value),
            let scheme = components.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            components.host != nil
        else {
            return nil
        }
        return components.url
    }
}
