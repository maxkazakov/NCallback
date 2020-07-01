import Foundation

public typealias ResultCallback<Response, Error: Swift.Error> = Callback<Result<Response, Error>>

extension Callback {
    // MARK: - completion
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

    // MARK: - mapping
    public func map<NewResponse, Response, Error: Swift.Error>(_ mapper: @escaping (Response) -> NewResponse) -> ResultCallback<NewResponse, Error>
        where ResultType == Result<Response, Error> {
            return flatMap {
                switch $0 {
                case .success(let r):
                    return .success(mapper(r))
                case .failure(let er):
                    return .failure(er)
                }
            }
    }

    public func mapError<Response, Error: Swift.Error, NewError: Swift.Error>(_ mapper: @escaping (Error) -> NewError) -> ResultCallback<Response, NewError>
        where ResultType == Result<Response, Error> {
            return flatMap {
                switch $0 {
                case .success(let r):
                    return .success(r)
                case .failure(let er):
                    return .failure(mapper(er))
                }
            }
    }
}

extension Callback {
    public static func success<Response, Error>(_ result: @escaping @autoclosure () -> Response) -> ResultCallback<Response, Error>
        where ResultType == Result<Response, Error> {
            return Callback { () -> Result<Response, Error> in
                return .success(result())
            }
    }

    public static func failure<Response, Error>(_ result: @escaping @autoclosure () -> Error) -> ResultCallback<Response, Error>
        where ResultType == Result<Response, Error> {
            return Callback { () -> Result<Response, Error> in
                return .failure(result())
            }
    }
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
