import Foundation
import NQueue

public typealias PendingResultCallback<Response, Error: Swift.Error> = PendingCallback<Result<Response, Error>>

public class PendingCallback<ResultType> {
    public typealias Callback = NCallback.Callback<ResultType>
    public typealias ServiceClosure = Callback.ServiceClosure
    public typealias Completion = Callback.Completion

    private var beforeCallback: Completion?
    private var deferredCallback: Completion?

    private var cached: Callback?
    private let mutex: Mutexing = Mutex.unfair

    public var isPending: Bool {
        cached != nil
    }

    public init() {
    }

    public func current(_ closure: @autoclosure () -> Callback) -> Callback {
        return current(closure)
    }

    public func current(_ closure: () -> Callback) -> Callback {
        return mutex.sync {
            let result: Callback

            if let current = cached {
                result = .init()
                current.deferred(result.complete)
            } else {
                result = closure()
                cached = result

                result.beforeComplete { [weak self] in
                    self?.cached = nil
                    self?.beforeCallback?($0)
                }

                result.deferred { [weak self] in
                    self?.deferredCallback?($0)
                }
            }

            return result
        }
    }

    public func current(_ closure: @escaping ServiceClosure) -> Callback {
        current(.init(start: closure))
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
        mutex.sync {
            let originalCallback = deferredCallback

            deferredCallback = { result in
                originalCallback?(result)
                callback(result)
            }
        }
        return self
    }

    @discardableResult
    public func beforeComplete(_ callback: @escaping Completion) -> Self {
        mutex.sync {
            let originalCallback = beforeCallback

            beforeCallback = { result in
                originalCallback?(result)
                callback(result)
            }
        }

        return self
    }
}
