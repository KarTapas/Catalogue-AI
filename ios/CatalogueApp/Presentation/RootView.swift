import SwiftUI

enum Route: Hashable {
    case category(String)
    case product(Int)
    case search(String)
}

struct RootView: View {
    let container: AppContainer
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomePlaceholderView()
                .navigationTitle("Catalogue")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(let name):
                        Text(name)
                    case .product(let id):
                        Text("Product \(id)")
                    case .search(let query):
                        Text(query)
                    }
                }
        }
        .tint(Palette.brand)
    }
}

private struct HomePlaceholderView: View {
    var body: some View {
        Text("Catalogue")
            .font(Typography.title)
            .foregroundStyle(Palette.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background)
    }
}
