import Foundation

private func makeVoid() -> Void {
}

private func makeVoid<T>(_: T) -> Void {
}

public extension Callback where ResultType == Void {
    func complete() {
        complete(makeVoid())
    }

    class func success() -> Callback<Void> {
        return .init(result: makeVoid())
    }
}

public extension Callback {
    func flatMapVoid() -> Callback<Void> {
        return flatMap(makeVoid)
    }

    func mapVoid<T, Error: Swift.Error>() -> ResultCallback<Void, Error> where ResultType == Result<T, Error> {
        return map(makeVoid)
    }

    func completeSuccessfully<Error: Swift.Error>() where ResultType == Result<Void, Error> {
        complete(.success(makeVoid()))
    }

    class func success<Error>() -> ResultCallback<Void, Error> {
        return .success(makeVoid())
    }

    func onComplete(options: CallbackOption = .default, _ callback: @escaping () -> Void) where ResultType == Void {
        onComplete(options: options) { _ in
            callback()
        }
    }
}
