import Foundation

public extension PendingCallback {
    func complete<Response, Error: Swift.Error>(_ error: Error) where ResultType == Result<Response, Error> {
        complete(.failure(error))
    }

    func complete<Response, Error: Swift.Error>(_ result: Response) where ResultType == Result<Response, Error> {
        complete(.success(result))
    }
}
