import SwiftUI

struct RemoteImage: View {
    let url: URL?
    let accessibilityLabel: String

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder(symbol: "photo", message: "Loading image")
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        placeholder(
                            symbol: "photo.badge.exclamationmark",
                            message: "Image unavailable"
                        )
                    @unknown default:
                        placeholder(
                            symbol: "photo.badge.exclamationmark",
                            message: "Image unavailable"
                        )
                    }
                }
            } else {
                placeholder(symbol: "photo", message: "Image unavailable")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private func placeholder(symbol: String, message: String) -> some View {
        VStack(spacing: Spacing.s8) {
            Image(systemName: symbol)
                .accessibilityHidden(true)
            Text(message)
                .font(Typography.caption)
        }
        .foregroundStyle(Palette.textSecondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RemoteImage(url: nil, accessibilityLabel: "Sample product image")
        .frame(height: 180)
        .padding()
}
