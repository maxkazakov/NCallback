import Foundation
import NQueue

public typealias PendingResultCallback<Response, Error: Swift.Error> = PendingCallback<Result<Response, Error>>

public class PendingCallback<ResultType> {
    public typealias Callback = NCallback.Callback<ResultType>
    public typealias ServiceClosure = Callback.ServiceClosure
    public typealias Completion = Callback.Completion

    private var beforeCallback: Completion?
    private var deferredCallback: Completion?

    private var isInProgress: Bool = false
    private var cached: Callback?
    private let mutex: Mutexing = Mutex.unfair

    public var isPending: Bool {
        return cached != nil
    }

    public init() {
    }

    public func current(_ closure: @autoclosure () -> Callback) -> Callback {
        return current(closure)
    }

    public func current(_ closure: () -> Callback) -> Callback {
        let original: Callback = mutex.sync {
            let computed: Callback
            if let cached = self.cached {
                computed = cached
            } else {
                computed = closure()
                self.cached = computed
            }
            return computed
        }

        return .init(start: { actual in
            self.mutex.sync {
                if self.isInProgress {
                    original.deferred(actual.complete)
                } else {
                    self.isInProgress = true
                    original.beforeComplete { [weak self] in
                        self?.cached = nil
                        self?.isInProgress = false
                        self?.beforeCallback?($0)
                    }

                    original.deferred { [weak self] in
                        self?.deferredCallback?($0)
                    }

                    actual.waitCompletion(of: original)
                }
            }
        })
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
