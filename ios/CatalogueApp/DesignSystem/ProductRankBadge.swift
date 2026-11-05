import SwiftUI

struct ProductRankBadge: View {
    let rank: Int

    var body: some View {
        Text("\(rank)")
            .font(Typography.caption)
            .foregroundStyle(Palette.surface)
            .padding(.horizontal, Spacing.s8)
            .padding(.vertical, Spacing.s4)
            .background(Palette.brand, in: Capsule())
            .accessibilityLabel("Rank \(rank)")
    }
}

#Preview {
    ProductRankBadge(rank: 1)
        .padding()
}
