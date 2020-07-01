import Foundation

public enum CallbackOption {
    case selfRetained
    case weakness
    case repeatable

    public static let `default`: CallbackOption = .selfRetained
}

public class Callback<ResultType> {
    public typealias Completion = (_ result: ResultType) -> Void
    public typealias ServiceClosure = (Callback) -> Void

    private let start: (Callback<ResultType>) -> Void
    private let stop: (Callback<ResultType>) -> Void
    private var beforeCallback: Completion?
    private var completeCallback: Completion?
    private var deferredCallback: Completion?
    private var strongyfy: Callback?
    private var options: CallbackOption = .default

    public required init(start: @escaping ServiceClosure,
                         stop: @escaping ServiceClosure = { _ in }) {
        self.start = start
        self.stop = stop
    }

    public convenience init(result: @escaping () -> ResultType) {
        self.init(start: { $0.complete(result()) })
    }

    public convenience init() {
        self.init(start: { _ in })
    }

    deinit {
        stop(self)
    }

    // MARK: - completion
    public func complete(_ result: ResultType) {
        beforeCallback?(result)
        completeCallback?(result)
        deferredCallback?(result)

        switch options {
        case .weakness, .selfRetained:
            strongyfy = nil
        case .repeatable:
            break
        }
    }

    public func cancel() {
        stop(self)
        completeCallback = nil
        strongyfy = nil
    }

    public func onComplete(options: CallbackOption = .default, _ callback: @escaping Completion) {
        self.options = options

        switch options {
        case .selfRetained:
            strongyfy = self
        case .repeatable,
             .weakness:
            break
        }

        assert(completeCallback == nil, "was configured twice, please check it!")
        completeCallback = callback

        start(self)
    }

    public func oneWay(options: CallbackOption = .default) {
        onComplete(options: options, { _ in })
    }

    // MARK: - mapping
    public func flatMap<NewResponse>(_ mapper: @escaping (ResultType) -> NewResponse) -> Callback<NewResponse> {
        let copy = Callback<NewResponse>(start: { _ in self.start(self) },
                                         stop: { _ in self.stop(self) })
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
        deferredCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }

    @available(*, deprecated, message: "use PendingCallback instead")
    public func andThen() -> Self {
        let copy = Self(start: { _ in })

        _ = deferred { [weak copy] in
            copy?.complete($0)
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
