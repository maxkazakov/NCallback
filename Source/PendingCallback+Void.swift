import Foundation

public extension PendingCallback where ResultType == Void {
    func complete() {
        complete(Void())
    }
}

public extension PendingCallback {
    func completeSuccessfully<Error: Swift.Error>() where ResultType == Result<Void, Error> {
        complete(.success(Void()))
    }
}
