import Foundation

public enum CallbackRetainCycle {
    case selfRetained
    case weakness
}

public class Callback<ResultType> {
    public typealias Completion = (_ result: ResultType) -> Void
    public typealias ServiceClosure = (Callback) -> Void

    private let start: (Callback<ResultType>) -> Void
    private let stop: (Callback<ResultType>) -> Void
    private var beforeCallback: Completion?
    private(set) var completeCallback: Completion?
    private var deferredCallback: Completion?
    private let original: Any?
    private var strongyfy: Callback?

    public required init(start: @escaping ServiceClosure,
                         stop: @escaping ServiceClosure = { _ in },
                         original: Any? = nil) {
        self.start = start
        self.stop = stop
        self.original = original
    }

    public convenience init(result: @escaping () -> ResultType) {
        self.init(start: { $0.complete(result()) })
    }

    deinit {
        stop(self)
    }

    // MARK: - completion
    public func complete(_ result: ResultType) {
        beforeCallback?(result)
        completeCallback?(result)
        deferredCallback?(result)
        strongyfy = nil
    }

    public func cancel() {
        stop(self)
        completeCallback = nil
        strongyfy = nil
    }

    public func onComplete(kind: CallbackRetainCycle = .selfRetained, _ callback: @escaping Completion) {
        switch kind {
        case .selfRetained:
            strongyfy = self
        case .weakness:
            strongyfy = nil
        }

        assert(completeCallback == nil)
        completeCallback = callback

        start(self)
    }

    public func oneWay(kind: CallbackRetainCycle = .selfRetained) {
        onComplete(kind: kind, { _ in })
    }

    // MARK: - mapping
    public func flatMap<NewResponse>(_ mapper: @escaping (ResultType) -> NewResponse) -> Callback<NewResponse> {
        let copy = Callback<NewResponse>(start: { [weak self] _ in self.map({ $0.start($0) }) },
                                         stop: { [weak self] _ in self.map({ $0.stop($0) }) },
                                         original: self)
        let originalCallback = completeCallback
        completeCallback = { [weak copy] result in
            originalCallback?(result)
            copy?.complete(mapper(result))
        }
        return copy
    }

    // MARK: - defer
    @discardableResult
    public func deferred(_ callback: @escaping Completion) -> Self {
        let originalCallback = deferredCallback
        self.deferredCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }

    public func andThen() -> Self {
        let copy = Self(start: { _ in })

        _ = deferred {
            copy.complete($0)
        }

        return copy
    }

    @discardableResult
    public func beforeComplete(_ callback: @escaping Completion) -> Self {
        let originalCallback = beforeCallback
        self.beforeCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }
}

extension Callback: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Callback, rhs: Callback) -> Bool {
        return lhs === rhs
    }
}

public func zip<ResponseA, ResponseB>(_ lhs: Callback<ResponseA>,
                                      _ rhs: Callback<ResponseB>,
                                      _ completion: @escaping (ResponseA, ResponseB) -> Void) {
    let task = {
        var a: ResponseA?
        var b: ResponseB?

        let check = {
            guard let a = a, let b = b else {
                return
            }
            completion(a, b)
        }

        lhs.onComplete { result in
            a = result
            check()
        }

        rhs.onComplete { result in
            b = result
            check()
        }
    }

    task()
}
