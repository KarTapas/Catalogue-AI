import SwiftUI

@main
struct CatalogueApp: App {
    private let startupState: StartupState

    init() {
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
                RootView(container: container)
            case .configurationError(let message):
                ConfigurationErrorView(message: message)
            }
        }
    }
}

private enum StartupState {
    case ready(AppContainer)
    case configurationError(String)
}
