import CatalogueDomain
import SwiftUI

struct ProductTile: View {
    let product: Product

    var body: some View {
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
}

#Preview {
    ProductTile(product: DesignPreviewData.product)
        .padding()
}
