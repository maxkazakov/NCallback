import Foundation

public extension Callback where ResultType == Ignorable {
    func complete() {
        complete(Ignorable())
    }
}

public extension Callback {
    func flatMapIgnorable() -> Callback<Ignorable> {
        return flatMap(Ignorable.init)
    }

    func mapIgnorable<T, Error: Swift.Error>() -> ResultCallback<Ignorable, Error> where ResultType == Result<T, Error> {
        map(Ignorable.init)
    }

    func completeSuccessfully<Error: Swift.Error>() where ResultType == Result<Ignorable, Error> {
        complete(.success(Ignorable()))
    }
}
