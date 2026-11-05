import CatalogueDomain
import SwiftUI

struct RatingView: View {
    let rating: Rating

    private var formattedRate: String {
        rating.rate.formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        HStack(spacing: Spacing.s4) {
            Image(systemName: "star.fill")
                .accessibilityHidden(true)
            Text(formattedRate)
            Text("(\(rating.count))")
                .foregroundStyle(Palette.textSecondary)
        }
        .font(Typography.caption)
        .foregroundStyle(Palette.brand)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text("Rating \(formattedRate) out of 5, \(rating.count) reviews")
        )
    }
}

#Preview {
    RatingView(rating: DesignPreviewData.product.rating)
        .padding()
}
