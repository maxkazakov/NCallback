import Foundation

public typealias PendingResultCallback<Response, Error: Swift.Error> = PendingCallback<Result<Response, Error>>

public class PendingCallback<ResultType> {
    public typealias Callback = NCallback.Callback<ResultType>
    public typealias ServiceClosure = Callback.ServiceClosure

    private var cached: Callback?

    public var isPending: Bool {
        cached != nil
    }

    public init() {
    }

    public func current(_ closure: @escaping ServiceClosure = { _ in }) -> Callback {
        let result: Callback
        if let current = cached {
            result = .init(start: {
                current.deferred($0.complete)
            })
        } else {
            result = .init(start: closure)
            cached = result

            result.beforeComplete { [weak self] _ in
                self?.cached = nil
            }
        }

        return result
    }

    public func complete(_ result: ResultType) {
        assert(cached != nil, "no one will receive this event while no subscribers")
        cached?.complete(result)
        cached = nil
    }

    public func cancel() {
        cached?.cancel()
        cached = nil
    }
}
