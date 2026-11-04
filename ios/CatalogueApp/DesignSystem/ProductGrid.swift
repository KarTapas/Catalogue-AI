import CatalogueDomain
import SwiftUI

private struct IndexedProduct: Identifiable {
    let product: Product
    let position: Int

    var id: Int {
        product.id
    }
}

struct ProductGrid<Content: View>: View {
    let products: [Product]
    private let content: (Product, Int) -> Content
    private var indexedProducts: [IndexedProduct] {
        products.enumerated().map { index, product in
            IndexedProduct(product: product, position: index + 1)
        }
    }

    init(
        products: [Product],
        @ViewBuilder content: @escaping (Product, Int) -> Content
    ) {
        self.products = products
        self.content = content
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150), spacing: Spacing.s12)],
            spacing: Spacing.s12
        ) {
            ForEach(indexedProducts) { item in
                content(item.product, item.position)
            }
        }
    }
}

#Preview {
    ProductGrid(products: [DesignPreviewData.product]) { product, _ in
        ProductTile(product: product)
    }
    .padding()
}
