import Foundation

public enum CallbackOption {
    case selfRetained
    case weakness
    case repeatable

    public static let `default`: CallbackOption = .selfRetained
}

public typealias ResultCallback<Response, Error: Swift.Error> = Callback<Result<Response, Error>>

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

    public var hashKey: String?

    public required init(start: @escaping ServiceClosure,
                         stop: @escaping ServiceClosure = { _ in }) {
        self.start = start
        self.stop = stop
    }

    public convenience init(result: @escaping () -> ResultType) {
        self.init(start: { $0.complete(result()) })
    }

    public convenience init(result: @escaping @autoclosure () -> ResultType) {
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
        case .weakness,
             .selfRetained:
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
    public func flatMap<NewResultType>(_ mapper: @escaping (ResultType) -> NewResultType) -> Callback<NewResultType> {
        let copy = Callback<NewResultType>(start: { _ in self.start(self) },
                                           stop: { _ in self.stop(self) })
        copy.hashKey = hashKey
        let originalCallback = completeCallback
        completeCallback = { [weak copy] result in
            originalCallback?(result)
            copy?.complete(mapper(result))
        }
        return copy
    }

    // MARK: - defer
    @discardableResult
    public func deferred(_ callback: @escaping Completion) -> Callback<ResultType> {
        let originalCallback = deferredCallback
        deferredCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }

    @discardableResult
    public func beforeComplete(_ callback: @escaping Completion) -> Callback<ResultType> {
        let originalCallback = beforeCallback
        self.beforeCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }

    // MARK: - ResultCallback
    public func complete<Response, Error: Swift.Error>(_ response: Response) where ResultType == Result<Response, Error> {
        complete(.success(response))
    }

    public func complete<Response, Error: Swift.Error>(_ error: Error) where ResultType == Result<Response, Error> {
        complete(.failure(error))
    }

    public func map<NewResponse, Response, Error: Swift.Error>(_ mapper: @escaping (Response) -> NewResponse) -> ResultCallback<NewResponse, Error>
        where ResultType == Result<Response, Error> {
            return flatMap { return $0.map(mapper) }
    }

    public func mapError<Response, Error: Swift.Error, NewError: Swift.Error>(_ mapper: @escaping (Error) -> NewError) -> ResultCallback<Response, NewError>
        where ResultType == Result<Response, Error> {
            return flatMap { return $0.mapError(mapper) }
    }

    public func recover<Response, Error: Swift.Error>(_ mapper: @escaping (Error) -> Response) -> Callback<Response>
        where ResultType == Result<Response, Error> {
            return flatMap {
                switch $0 {
                case .success(let v):
                    return v
                case .failure(let e):
                    return mapper(e)
                }
            }
    }

    public func recover<Response, Error: Swift.Error>(_ recovered: @escaping () -> Response) -> Callback<Response>
        where ResultType == Result<Response, Error> {
            return flatMap {
                switch $0 {
                case .success(let v):
                    return v
                case .failure:
                    return recovered()
                }
            }
    }

    public func recover<Response, Error: Swift.Error>(_ recovered: @escaping @autoclosure () -> Response) -> Callback<Response>
        where ResultType == Result<Response, Error> {
            return flatMap {
                switch $0 {
                case .success(let v):
                    return v
                case .failure:
                    return recovered()
                }
            }
    }

    public class func success<Response, Error>(_ result: @escaping @autoclosure () -> Response) -> ResultCallback<Response, Error>
        where ResultType == Result<Response, Error> {
            return Callback { return .success(result()) }
    }

    public class func failure<Response, Error>(_ result: @escaping @autoclosure () -> Error) -> ResultCallback<Response, Error>
        where ResultType == Result<Response, Error> {
            return Callback { return .failure(result()) }
    }
}

// MARK: - Hashable
extension Callback: Hashable {
    public func hash(into hasher: inout Hasher) {
        hashKey.map({ hasher.combine($0) }) ?? hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Callback, rhs: Callback) -> Bool {
        switch (lhs.hashKey, rhs.hashKey) {
        case (.some(let a), .some(let b)):
            return a == b
        case (.some, _):
            return false
        case (_, .some):
            return false
        case (.none, .none):
            return lhs === rhs
        }
    }
}

// MARK: - zip
public func zip<ResponseA, ResponseB>(_ lhs: Callback<ResponseA>,
                                      _ rhs: Callback<ResponseB>) -> Callback<(ResponseA, ResponseB)> {
    let startTask: Callback<(ResponseA, ResponseB)>.ServiceClosure = { [weak lhs, weak rhs] original in
        var a: ResponseA?
        var b: ResponseB?

        let check = {
            if let a = a, let b = b {
                let result = (a, b)
                original.complete(result)
            }
        }

        lhs?.onComplete(options: .selfRetained) { result in
            a = result
            check()
        }

        rhs?.onComplete(options: .selfRetained) { result in
            b = result
            check()
        }
    }

    let stopTask: Callback<(ResponseA, ResponseB)>.ServiceClosure = { [weak lhs, weak rhs] _ in
        lhs?.cancel()
        rhs?.cancel()
    }

    return .init(start: startTask,
                 stop: stopTask)
}

public func zip<ResponseA, ResponseB, Error: Swift.Error>(_ lhs: ResultCallback<ResponseA, Error>,
                                                          _ rhs: ResultCallback<ResponseB, Error>) -> ResultCallback<(ResponseA, ResponseB), Error>  {
    let startTask: ResultCallback<(ResponseA, ResponseB), Error>.ServiceClosure = { [weak lhs, weak rhs] original in
        var a: Result<ResponseA, Error>?
        var b: Result<ResponseB, Error>?

        let check = { [weak lhs, weak rhs] in
            if let a = a, let b = b {
                switch (a, b) {
                case (.success(let a), .success(let b)):
                    let result: (ResponseA, ResponseB) = (a, b)
                    original.complete(result)
                case (.failure(let a), _),
                     (_, .failure(let a)):
                    original.complete(a)
                }
            } else if let a = a {
                switch a {
                case .success:
                    break
                case .failure(let e):
                    original.complete(e)
                    rhs?.cancel()
                }
            } else if let b = b {
                switch b {
                case .success:
                    break
                case .failure(let e):
                    original.complete(e)
                    lhs?.cancel()
                }
            }
        }

        lhs?.onComplete(options: .selfRetained) { result in
            a = result
            check()
        }

        rhs?.onComplete(options: .selfRetained) { result in
            b = result
            check()
        }
    }

    let stopTask: ResultCallback<(ResponseA, ResponseB), Error>.ServiceClosure = { [weak lhs, weak rhs] _ in
        lhs?.cancel()
        rhs?.cancel()
    }

    return .init(start: startTask,
                 stop: stopTask)
}
