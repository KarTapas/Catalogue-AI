import CatalogueDomain
import SwiftUI

struct ProductTile: View {
    let product: Product
    private let action: (() -> Void)?

    init(product: Product, action: (() -> Void)? = nil) {
        self.product = product
        self.action = action
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    tileContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(accessibilityLabel))
            } else {
                tileContent
            }
        }
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            RemoteImage(
                url: product.imageURL,
                accessibilityLabel: product.title
            )
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: Radius.r8))

            Text(product.title)
                .font(Typography.body)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(2)

            Text(product.price.formattedAmount)
                .font(Typography.headline)
                .foregroundStyle(Palette.textPrimary)

            RatingView(rating: product.rating)
        }
        .padding(Spacing.s12)
        .background(
            Palette.surface,
            in: RoundedRectangle(cornerRadius: Radius.r12)
        )
        .accessibilityElement(children: .combine)
    }

    private var accessibilityLabel: String {
        let rating = product.rating.rate.formatted(.number.precision(.fractionLength(1)))
        return "\(product.title), \(product.price.formattedAmount), rating \(rating), \(product.rating.count) reviews"
    }
}

#Preview {
    ProductTile(product: DesignPreviewData.product)
        .padding()
}
