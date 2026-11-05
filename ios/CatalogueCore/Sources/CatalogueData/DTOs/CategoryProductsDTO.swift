import Foundation

struct CategoryProductsDTO: Decodable {
    let category: String
    let topRated: [ProductDTO]
    let others: [ProductDTO]
}
