import CatalogueDomain

enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(AppError)

    var isLoading: Bool {
        if case .loading = self {
            true
        } else {
            false
        }
    }

    var value: Value? {
        if case .loaded(let value) = self {
            value
        } else {
            nil
        }
    }
}

extension LoadState: Equatable where Value: Equatable {}
