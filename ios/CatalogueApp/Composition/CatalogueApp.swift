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
        let prefix = "category:"
        guard
            let route = ProcessInfo.processInfo.environment["UI_PREVIEW_ROUTE"],
            route.hasPrefix(prefix)
        else {
            return nil
        }

        let category = String(route.dropFirst(prefix.count))
        guard !category.isEmpty else {
            return nil
        }
        return .category(category)
    }
    #endif
}

private enum StartupState {
    case ready(AppContainer)
    case configurationError(String)
}
