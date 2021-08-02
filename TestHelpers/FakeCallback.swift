import Foundation
import NSpry
import NCallback
import NQueue

@testable import NCallback

typealias FakeResultCallback<Response, Error: Swift.Error> = FakeCallback<Result<Response, Error>>

final class FakeCallback<ResultType>: Callback<ResultType>, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case success = "success(_:)"
        case failure = "failure(_:)"
    }

    enum Function: String, StringRepresentable {
        case complete = "complete(_:)"
        case cleanup = "cleanup()"

        case onComplete = "onComplete(options:_:)"
        case oneWay = "oneWay(kind:)"

        case flatMap = "flatMap(_:)"

        case deferred = "deferred(_:)"
        case beforeComplete = "beforeComplete(_:)"

        case map = "map(_:)"
        case mapError = "mapError(_:)"

        case polling = "polling(scheduleQueue:retryCount:idleTimeInterval:minimumWaitingTime:shouldRepeat:response:)"
        case scheduleInQueue = "schedule(in:)"
    }

    override func complete(_ result: ResultType) {
        return spryify(arguments: result)
    }

    override func cleanup() {
        return spryify()
    }

    var onComplete: Completion?
    override func onComplete(options: CallbackOption = .default, _ callback: @escaping Completion) {
        self.onComplete = callback
        return spryify(arguments: options, callback)
    }

    override func oneWay(options: CallbackOption = .default) {
        return spryify(arguments: options)
    }

    override func flatMap<NewResponse>(_ mapper: @escaping (ResultType) -> NewResponse) -> Callback<NewResponse> {
        return spryify(arguments: mapper)
    }

    var deferred: Completion?
    @discardableResult
    override func deferred(_ callback: @escaping Completion) -> Callback<ResultType> {
        self.deferred = callback
        return spryify(arguments: callback)
    }

    var beforeComplete: Completion?
    @discardableResult
    override func beforeComplete(_ callback: @escaping Completion) -> Callback<ResultType> {
        self.beforeComplete = callback
        return spryify(arguments: callback)
    }

    override func complete<Response, Error: Swift.Error>(_ response: Response)
    where ResultType == Result<Response, Error> {
        return spryify(arguments: response)
    }

    override func complete<Response, Error: Swift.Error>(_ error: Error)
    where ResultType == Result<Response, Error> {
        return spryify(arguments: error)
    }

    override func map<NewResponse, Response, Error: Swift.Error>(_ mapper: @escaping (Response) -> NewResponse) -> ResultCallback<NewResponse, Error>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: mapper)
    }

    override func mapError<Response, Error: Swift.Error, NewError: Swift.Error>(_ mapper: @escaping (Error) -> NewError) -> ResultCallback<Response, NewError>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: mapper)
    }

    override static func success<Response, Error>(_ result: @escaping @autoclosure () -> Response) -> ResultCallback<Response, Error>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: result())
    }

    override static func failure<Response, Error>(_ result: @escaping @autoclosure () -> Error) -> ResultCallback<Response, Error>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: result())
    }

    override func polling<Response, Error>(scheduleQueue: Queueable? = nil,
                                           retryCount: Int = 5,
                                           idleTimeInterval: TimeInterval = 10,
                                           minimumWaitingTime: TimeInterval? = nil,
                                           shouldRepeat: @escaping (Result<Response, Error>) -> Bool = { _ in false },
                                           response: @escaping (Result<Response, Error>) -> Void = { _ in }) -> Callback<Result<Response, Error>>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: scheduleQueue, retryCount, idleTimeInterval, minimumWaitingTime, shouldRepeat, response)
    }

    override func schedule(in queue: DelayedQueue) -> Self {
        return spryify(arguments: queue)
    }

    override func schedule(in queue: Queueable) -> Self {
        return spryify(arguments: queue)
    }
}
