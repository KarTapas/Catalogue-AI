import Foundation

enum APIJSONFixtures {
    static let documentedProductTitle =
        "Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops"
    static let documentedProductImage =
        "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg"

    static func product(
        id: Int = 1,
        title: String = documentedProductTitle,
        description: String = "Your perfect pack for everyday use and walks in the forest.",
        category: String = "men's clothing",
        amount: String = "109.95",
        currency: String = "USD",
        imageURL: String? = documentedProductImage,
        rate: Double = 3.9,
        ratingCount: Int = 120
    ) -> String {
        let imageJSON = imageURL.map { "\"\($0)\"" } ?? "null"
        return """
        {
          "id": \(id),
          "title": "\(title)",
          "description": "\(description)",
          "category": "\(category)",
          "price": {"amount": "\(amount)", "currency": "\(currency)"},
          "imageUrl": \(imageJSON),
          "rating": {"rate": \(rate), "count": \(ratingCount)}
        }
        """
    }

    static func array(_ products: [String]) -> String {
        "[\(products.joined(separator: ","))]"
    }

    static func categoryProducts(
        category: String = "men's clothing",
        topRated: [String],
        others: [String]
    ) -> String {
        """
        {
          "category": "\(category)",
          "topRated": [\(topRated.joined(separator: ","))],
          "others": [\(others.joined(separator: ","))]
        }
        """
    }
}
