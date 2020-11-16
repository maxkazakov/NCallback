import Foundation

extension Callback {
    private func startPolling<Response, Error>(with info: PollingInfo<Response, Error>, retryCount: Int)
    where ResultType == Result<Response, Error>, Error: Swift.Error {
        onComplete(options: .repeatable(.selfRetained)) { result in
            if info.canRepeat(retryCount) && info.shouldRepeat(result) {
                self.schedulePolling(with: info, retryCount: retryCount - 1)
            } else {
                switch result {
                case .success:
                    info.complete(result)
                case .failure(let error):
                    if let failureCompletion = info.failureCompletion {
                        info.complete(.failure(failureCompletion(error)))
                    } else {
                        info.complete(.failure(error))
                    }
                }
            }
        }
    }

    private func schedulePolling<Response, Error>(with info: PollingInfo<Response, Error>, retryCount: Int)
    where ResultType == Result<Response, Error>, Error: Swift.Error {
        info.scheduleQueue.asyncAfter(.now() + info.timeoutInterval) {
            self.startPolling(with: info, retryCount: retryCount)
        }
    }

    // was marked internal to implement logic in the separated file
    // swift can't override methods from extensions, but it's neede for Fake
    internal func hiddenPolling<Response, Error>(scheduleQueue: CallbackQueue,
                                                 responseQueue: CallbackQueue,
                                                 retryCount: Int,
                                                 timeoutInterval: TimeInterval,
                                                 minimumWaitingTime: TimeInterval?,
                                                 timeoutFailureCompletion: ((Error) -> Error)?,
                                                 shouldRepeat: ((Result<Response, Error>) -> Bool)?) -> Callback
    where ResultType == Result<Response, Error>, Error: Swift.Error {
        return Callback { actual in
            let info = PollingInfo(scheduleQueue: scheduleQueue,
                                   responseQueue: responseQueue,
                                   actual: actual,
                                   timeoutInterval: timeoutInterval,
                                   failureCompletion: timeoutFailureCompletion,
                                   shouldRepeat: shouldRepeat ?? { _ in false },
                                   minimumWaitingTime: minimumWaitingTime)
            self.startPolling(with: info, retryCount: retryCount)
        } stop: { _ in
            self.cancel()
        }
    }
}

private struct PollingInfo<Response, Error: Swift.Error> {
    private let actual: ResultCallback<Response, Error>
    private let responseQueue: CallbackQueue

    let scheduleQueue: CallbackQueue

    let timeoutInterval: TimeInterval
    let failureCompletion: ((Error) -> Error)?
    let shouldRepeat: (Result<Response, Error>) -> Bool

    let timestamp: TimeInterval
    let minimumWaitingTime: TimeInterval?

    internal init(scheduleQueue: CallbackQueue,
                  responseQueue: CallbackQueue,
                  actual: ResultCallback<Response, Error>,
                  timeoutInterval: TimeInterval,
                  failureCompletion: ((Error) -> Error)?,
                  shouldRepeat: @escaping (Result<Response, Error>) -> Bool,
                  minimumWaitingTime: TimeInterval?) {
        self.scheduleQueue = scheduleQueue
        self.responseQueue = responseQueue
        self.actual = actual
        self.timeoutInterval = timeoutInterval
        self.failureCompletion = failureCompletion
        self.shouldRepeat = shouldRepeat
        self.timestamp = Self.timestamp()
        self.minimumWaitingTime = minimumWaitingTime
    }

    func complete(_ result: Result<Response, Error>) {
        responseQueue.async { [actual] in
            actual.complete(result)
        }
    }

    private func canWait() -> Bool {
        if let minimumWaitingTime = minimumWaitingTime {
            return max(Self.timestamp() - self.timestamp, 0) < minimumWaitingTime
        }
        return false
    }

    func canRepeat(_ retryCount: Int) -> Bool {
        retryCount > 0 || canWait()
    }

    private static func timestamp() -> TimeInterval {
        max(Date().timeIntervalSinceReferenceDate, 0)
    }
}
