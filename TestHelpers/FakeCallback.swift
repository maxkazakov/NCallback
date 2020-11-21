import Foundation
import Spry

@testable import NCallback

public typealias FakeResultCallback<Response, Error: Swift.Error> = FakeCallback<Result<Response, Error>>

final
public class FakeCallback<ResultType>: Callback<ResultType>, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case success = "success(_:)"
        case failure = "failure(_:)"
    }

    public enum Function: String, StringRepresentable {
        case complete = "complete(_:)"
        case cancel = "cancel()"

        case onComplete = "onComplete(options:_:)"
        case oneWay = "oneWay(kind:)"

        case flatMap = "flatMap(_:)"

        case deferred = "deferred(_:)"
        case beforeComplete = "beforeComplete(_:)"

        case map = "map(_:)"
        case mapError = "mapError(_:)"

        case polling = "polling(scheduleQueue:retryCount:timeoutInterval:minimumWaitingTime:timeoutFailureCompletion:shouldRepeat:)"
        case scheduleInQueue = "schedule(in:)"
    }

    public override func complete(_ result: ResultType) {
        return spryify(arguments: result)
    }

    public override func cancel() {
        return spryify()
    }

    public var onComplete: Completion?
    public override func onComplete(options: CallbackOption = .default, _ callback: @escaping Completion) {
        self.onComplete = callback
        return spryify(arguments: options, callback)
    }

    public override func oneWay(options: CallbackOption = .default) {
        return spryify(arguments: options)
    }

    public override func flatMap<NewResponse>(_ mapper: @escaping (ResultType) -> NewResponse) -> Callback<NewResponse> {
        return spryify(arguments: mapper)
    }

    public var deferred: Completion?
    @discardableResult
    public override func deferred(_ callback: @escaping Completion) -> Callback<ResultType> {
        self.deferred = callback
        return spryify(arguments: callback)
    }

    public var beforeComplete: Completion?
    @discardableResult
    public override func beforeComplete(_ callback: @escaping Completion) -> Callback<ResultType> {
        self.beforeComplete = callback
        return spryify(arguments: callback)
    }

    public override func complete<Response, Error: Swift.Error>(_ response: Response)
    where ResultType == Result<Response, Error> {
        return spryify(arguments: response)
    }

    public override func complete<Response, Error: Swift.Error>(_ error: Error)
    where ResultType == Result<Response, Error> {
        return spryify(arguments: error)
    }

    public override func map<NewResponse, Response, Error: Swift.Error>(_ mapper: @escaping (Response) -> NewResponse) -> ResultCallback<NewResponse, Error>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: mapper)
    }

    public override func mapError<Response, Error: Swift.Error, NewError: Swift.Error>(_ mapper: @escaping (Error) -> NewError) -> ResultCallback<Response, NewError>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: mapper)
    }

    public override static func success<Response, Error>(_ result: @escaping @autoclosure () -> Response) -> ResultCallback<Response, Error>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: result())
    }

    public override static func failure<Response, Error>(_ result: @escaping @autoclosure () -> Error) -> ResultCallback<Response, Error>
    where ResultType == Result<Response, Error> {
        return spryify(arguments: result())
    }

    public override func polling<Response, Error>(scheduleQueue: DispatchCallbackQueue,
                                                  retryCount: Int = 5,
                                                  timeoutInterval: TimeInterval = 10,
                                                  minimumWaitingTime: TimeInterval? = nil,
                                                  timeoutFailureCompletion: @escaping (Error) -> Error = { $0 },
                                                  shouldRepeat: @escaping (ResultType) -> Bool = { _ in false }) -> Callback<ResultType>
    where ResultType == Result<Response, Error>, Error: Swift.Error {
        return spryify(arguments: scheduleQueue, retryCount, timeoutInterval, minimumWaitingTime, timeoutFailureCompletion, shouldRepeat)
    }

    public override func schedule(in queue: CallbackQueue) {
        return spryify(arguments: queue)
    }

    public override func schedule(in queue: DispatchCallbackQueue) {
        return spryify(arguments: queue)
    }
}
