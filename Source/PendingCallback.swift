import Foundation

public typealias ResultPendingCallback<Response, Error: Swift.Error> = PendingCallback<Result<Response, Error>>

public class PendingCallback<ResultType> {
    public typealias Generator = () -> Callback<ResultType>

    private let generator: Generator
    private var saved: Callback<ResultType>?

    public init(generator: @escaping Generator) {
        self.generator = generator
    }

    public func current() -> Callback<ResultType> {
        let result: Callback<ResultType>
        if let current = saved {
            result = Callback<ResultType>(start: { _ in })

            _ = current.deferred { [weak result] in
                result?.complete($0)
            }
        } else {
            result = generator()
            saved = result
        }

        return result
    }
}
