import Foundation
import NQueue

public typealias PendingResultCallback<Response, Error: Swift.Error> = PendingCallback<Result<Response, Error>>

public class PendingCallback<ResultType> {
    public typealias Callback = NCallback.Callback<ResultType>
    public typealias ServiceClosure = Callback.ServiceClosure
    public typealias Completion = Callback.Completion

    @Atomic
    private var isInProgress: Bool = false

    @Atomic
    private var cached: Callback?

    private var beforeCallback: Completion?
    private var deferredCallback: Completion?

    public var isPending: Bool {
        return cached != nil
    }

    public init() {
        _isInProgress = Atomic(wrappedValue: false,
                               mutex: Mutex.pthread(.recursive),
                               read: .sync,
                               write: .sync)

        _cached = Atomic(wrappedValue: nil,
                         mutex: Mutex.pthread(.recursive),
                         read: .sync,
                         write: .sync)
    }

    public func current(_ closure: @escaping ServiceClosure) -> Callback {
        return current(.init(start: closure))
    }

    public func current(_ closure: @autoclosure () -> Callback) -> Callback {
        return current(closure)
    }

    public func current(_ closure: () -> Callback) -> Callback {
        return $cached.mutate { cached in
            let computed: Callback
            if let cached = cached {
                computed = cached
            } else {
                computed = closure()
                cached = computed
            }

            return .init(start: { [weak self, computed] actual in
                guard let self = self else {
                    actual.waitCompletion(of: computed)
                    return
                }

                if self.isInProgress {
                    computed.deferred(actual.complete)
                } else {
                    self.isInProgress = true

                    computed.beforeComplete { [weak self] result in
                        self?.isInProgress = false
                        self?.cached = nil
                        self?.beforeCallback?(result)
                    }
                    .deferred { [weak self] result in
                        self?.deferredCallback?(result)
                    }
                    .onComplete(options: .weakness) { result in
                        actual.complete(result)
                    }
                }
            })
        }
    }

    public func complete(_ result: ResultType) {
        assert(cached != nil, "nobody will receive this event while cache is empty")
        cached?.complete(result)
    }

    public func cancel() {
        isInProgress = false
        cached?.cleanup()
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
