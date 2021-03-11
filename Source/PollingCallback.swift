import Foundation

let defaultScheduleQueue: DispatchCallbackQueue = DispatchQueue(label: "PollingCallback",
                                                                qos: DispatchQoS.utility,
                                                                attributes: DispatchQueue.Attributes.concurrent)

final
class PollingCallback<Response, Error: Swift.Error> {
    typealias ResultType = Result<Response, Error>

    private let generator: () -> Callback<ResultType>
    private var cached: Callback<ResultType>?

    private let scheduleQueue: DispatchCallbackQueue

    private let timeoutInterval: TimeInterval
    private let failureCompletion: (Error) -> Error
    private let shouldRepeat: (ResultType) -> Bool
    private let response: (ResultType) -> Void

    private let timestamp: TimeInterval
    private let minimumWaitingTime: TimeInterval?
    private let retryCount: Int

    init(scheduleQueue: DispatchCallbackQueue = defaultScheduleQueue,
         generator: @escaping @autoclosure () -> Callback<ResultType>,
         timeoutInterval: TimeInterval = 5,
         timeoutFailureCompletion: @escaping ((Error) -> Error) = { $0 },
         shouldRepeat: @escaping (ResultType) -> Bool = { _ in false },
         retryCount: Int = 5,
         minimumWaitingTime: TimeInterval? = nil,
         response: @escaping (Result<Response, Error>) -> Void = { _ in }) {
        self.scheduleQueue = scheduleQueue
        self.generator = generator
        self.timeoutInterval = timeoutInterval
        self.failureCompletion = timeoutFailureCompletion
        self.shouldRepeat = shouldRepeat
        self.timestamp = Self.timestamp()
        self.retryCount = retryCount
        self.minimumWaitingTime = minimumWaitingTime
        self.response = response
    }

    func start() -> Callback<ResultType> {
        return Callback { actual in
            self.startPolling(actual, retryCount: self.retryCount)
        } stop: { _ in
            self.cancel()
        }
    }

    func cancel() {
        cached?.cancel()
    }

    private func new() -> Callback<ResultType> {
        let new = generator()
        cached = new
        return new.beforeComplete { [unowned self] _ in
            self.cached = nil
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

    private func startPolling(_ actual: Callback<ResultType>, retryCount: Int) {
        new().onComplete(options: .repeatable(.weakness)) { [unowned self] result in
            if self.canRepeat(retryCount) && self.shouldRepeat(result) {
                self.schedulePolling(actual, retryCount: retryCount - 1)
            } else {
                switch result {
                case .success:
                    actual.complete(result)
                case .failure(let error):
                    actual.complete(.failure(self.failureCompletion(error)))
                }
            }

            self.response(result)
        }
    }

    private func schedulePolling(_ actual: Callback<ResultType>, retryCount: Int) {
        scheduleQueue.asyncAfter(.now() + timeoutInterval) { [unowned self] in
            self.startPolling(actual, retryCount: retryCount)
        }
    }
}
