import Foundation

private enum State<R> {
    case pending
    case value(R)
}

public func zip<Response>(_ input: Callback<Response>...) -> Callback<[Response]> {
    return zip(input)
}

public func zip<Response>(_ input: [Callback<Response>]) -> Callback<[Response]> {
    if input.isEmpty {
        return .init(result: [])
    }

    var array = input
    var result: [State<Response>] = Array(repeating: .pending, count: array.count)
    let startTask: Callback<[Response]>.ServiceClosure = { original in
        for info in array.enumerated() {
            let offset = info.offset
            info.element.onComplete(options: .weakness) { [weak original] response in
                result.insert(.value(response), at: offset)

                let actual: [Response] = result.compactMap {
                    switch $0 {
                    case .pending:
                        return nil
                    case .value(let r):
                        return r
                    }
                }

                if array.count == actual.count {
                    original?.complete(actual)
                    array.removeAll()
                }
            }
        }
    }

    let stopTask: Callback<[Response]>.ServiceClosure = { _ in
        array.removeAll()
    }

    return .init(start: startTask,
                 stop: stopTask)
}

public func zip<ResponseA, ResponseB, Error: Swift.Error>(_ lhs: ResultCallback<ResponseA, Error>,
                                                          _ rhs: ResultCallback<ResponseB, Error>) -> ResultCallback<(ResponseA, ResponseB), Error> {
    let startTask: ResultCallback<(ResponseA, ResponseB), Error>.ServiceClosure = { original in
        var a: Result<ResponseA, Error>?
        var b: Result<ResponseB, Error>?

        let check = { [weak lhs, weak rhs, weak original] in
            if let a = a, let b = b {
                switch (a, b) {
                case (.success(let a), .success(let b)):
                    let result: (ResponseA, ResponseB) = (a, b)
                    original?.complete(result)
                case (_, .failure(let a)),
                     (.failure(let a), _):
                    original?.complete(a)
                }
            } else if let a = a {
                switch a {
                case .success:
                    break
                case .failure(let e):
                    original?.complete(e)
                    rhs?.cleanup()
                }
            } else if let b = b {
                switch b {
                case .success:
                    break
                case .failure(let e):
                    original?.complete(e)
                    lhs?.cleanup()
                }
            }
        }

        lhs.onComplete(options: .weakness) { result in
            a = result
            check()
        }

        rhs.onComplete(options: .weakness) { result in
            b = result
            check()
        }
    }

    let stopTask: ResultCallback<(ResponseA, ResponseB), Error>.ServiceClosure = { _ in
        lhs.cleanup()
        rhs.cleanup()
    }

    return .init(start: startTask,
                 stop: stopTask)
}

public func zipTuple<ResponseA, ResponseB>(_ lhs: Callback<ResponseA>,
                                           _ rhs: Callback<ResponseB>) -> Callback<(ResponseA, ResponseB)> {
    var a: ResponseA?
    var b: ResponseB?

    let startTask: Callback<(ResponseA, ResponseB)>.ServiceClosure = { original in
        let check = { [weak original] in
            if let a = a, let b = b {
                let result = (a, b)
                original?.complete(result)
            }
        }

        lhs.onComplete(options: .weakness) { result in
            a = result
            check()
        }

        rhs.onComplete(options: .weakness) { result in
            b = result
            check()
        }
    }

    return .init(start: startTask)
}
