import Foundation

public typealias PendingResultCallback<Response, Error: Swift.Error> = PendingCallback<Result<Response, Error>>

public class PendingCallback<ResultType> {
    public typealias Callback = NCallback.Callback<ResultType>
    public typealias ServiceClosure = Callback.ServiceClosure
    public typealias Completion = Callback.Completion

    private var beforeCallback: Completion?
    private var deferredCallback: Completion?

    private var cached: Callback?

    public var isPending: Bool {
        cached != nil
    }

    public init() {
    }

    public func current(_ closure: @escaping @autoclosure () -> Callback) -> Callback {
        current {
            $0.waitCompletion(of: closure())
        }
    }

    public func current(_ closure: @escaping ServiceClosure) -> Callback {
        let result: Callback
        if let current = cached {
            result = .init(start: {
                current.deferred($0.complete)
            })
        } else {
            result = .init(start: closure)
            cached = result

            result.beforeComplete { [weak self] in
                self?.cached = nil
                self?.beforeCallback?($0)
            }

            result.deferred { [weak self] in
                self?.cached = nil
                self?.deferredCallback?($0)
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

    @discardableResult
    public func deferred(_ callback: @escaping Completion) -> Self {
        let originalCallback = deferredCallback
        deferredCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }

    @discardableResult
    public func beforeComplete(_ callback: @escaping Completion) -> Self {
        let originalCallback = beforeCallback
        beforeCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }
}
