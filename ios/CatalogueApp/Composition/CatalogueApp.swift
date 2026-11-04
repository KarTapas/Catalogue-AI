import Foundation
import SwiftUI

@main
struct CatalogueApp: App {
    private let startupState: StartupState
    private let initialRoute: Route?

    init() {
        #if DEBUG
        initialRoute = Self.debugPreviewRoute()
        #else
        initialRoute = nil
        #endif

        do {
            let configuration = try AppConfig()
            startupState = .ready(AppContainer(configuration: configuration))
        } catch {
            startupState = .configurationError(error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch startupState {
            case .ready(let container):
                RootView(container: container, initialRoute: initialRoute)
            case .configurationError(let message):
                ConfigurationErrorView(message: message)
            }
        }
    }

    #if DEBUG
    private static func debugPreviewRoute() -> Route? {
        guard let route = ProcessInfo.processInfo.environment["UI_PREVIEW_ROUTE"] else {
            return nil
        }

        let categoryPrefix = "category:"
        if route.hasPrefix(categoryPrefix) {
            let category = String(route.dropFirst(categoryPrefix.count))
            guard !category.isEmpty else {
                return nil
            }
            return .category(category)
        }

        let searchPrefix = "search:"
        if route.hasPrefix(searchPrefix) {
            let query = String(route.dropFirst(searchPrefix.count))
            guard !query.isEmpty else {
                return nil
            }
            return .search(query)
        }

        let productPrefix = "product:"
        if route.hasPrefix(productPrefix) {
            let rawID = String(route.dropFirst(productPrefix.count))
            guard let productID = Int(rawID) else {
                return nil
            }
            return .product(productID)
        }

        return nil
    }
    #endif
}

private enum StartupState {
    case ready(AppContainer)
    case configurationError(String)
}
