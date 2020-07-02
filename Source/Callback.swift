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

    public func onSuccess<Response, Error: Swift.Error>(options: CallbackOption = .default,
                                                        _ callback: @escaping (_ result: Response) -> Void) where ResultType == Result<Response, Error> {
        onComplete(options: options) {
            switch $0 {
            case .success(let value):
                callback(value)
            case .failure:
                break
            }
        }
    }

    public func map<NewResponse, Response, Error: Swift.Error>(_ mapper: @escaping (Response) -> NewResponse) -> ResultCallback<NewResponse, Error>
        where ResultType == Result<Response, Error> {
            return flatMap { return $0.map(mapper) }
    }

    public func mapError<Response, Error: Swift.Error, NewError: Swift.Error>(_ mapper: @escaping (Error) -> NewError) -> ResultCallback<Response, NewError>
        where ResultType == Result<Response, Error> {
            return flatMap { return $0.mapError(mapper) }
    }

    public class func success<Response, Error>(_ result: @escaping @autoclosure () -> Response) -> ResultCallback<Response, Error>
        where ResultType == Result<Response, Error> {
            return Callback {
                return .success(result())
            }
    }

    public class func failure<Response, Error>(_ result: @escaping @autoclosure () -> Error) -> ResultCallback<Response, Error>
        where ResultType == Result<Response, Error> {
            return Callback {
                return .failure(result())
            }
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

public func zip<ResponseA, ResponseB, Error: Swift.Error>(_ lhs: ResultCallback<ResponseA, Error>,
                                                          _ rhs: ResultCallback<ResponseB, Error>,
                                                          _ completion: @escaping (Result<(ResponseA, ResponseB), Error>) -> Void) {
    zip(lhs, rhs) {
        switch ($0, $1) {
        case (.success(let a), .success(let b)):
            completion(.success((a, b)))
        case (.failure(let error), _):
            completion(.failure(error))
        case (_, .failure(let error)):
            completion(.failure(error))
        }
    }
}
