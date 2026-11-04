import Foundation

struct ProductDTO: Decodable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: PriceDTO
    let imageUrl: String?
    let rating: RatingDTO
}

struct PriceDTO: Decodable {
    let amount: String
    let currency: String
}

struct RatingDTO: Decodable {
    let rate: Double
    let count: Int
}
