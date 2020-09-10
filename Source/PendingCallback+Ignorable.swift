import Foundation

public extension PendingCallback where ResultType == Ignorable {
    func complete() {
        complete(Ignorable())
    }
}

public extension PendingCallback {
    func completeSuccessfully<Error: Swift.Error>() where ResultType == Result<Ignorable, Error> {
        complete(.success(Ignorable()))
    }

    func complete<Response, Error: Swift.Error>(_ error: Error) where ResultType == Result<Response, Error> {
        complete(.failure(error))
    }

    func complete<Response, Error: Swift.Error>(_ result: Response) where ResultType == Result<Response, Error> {
        complete(.success(result))
    }
}
