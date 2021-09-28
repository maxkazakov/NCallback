import Foundation

@discardableResult
public func sync<T>(_ callback: Callback<T>,
                    seconds: Double? = nil,
                    timeoutResult timeout: @autoclosure () -> T) -> T {
    return sync(callback,
                seconds: seconds,
                timeoutResult: timeout)
}

@discardableResult
public func sync<T>(_ callback: Callback<T>,
                    seconds: Double? = nil,
                    timeoutResult timeout: () -> T) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    var result: T!

    callback.onComplete(options: .selfRetained) {
        result = $0
        semaphore.signal()
    }

    assert(seconds.map { $0 > 0 } ?? true, "seconds must be nil or greater than 0")

    if let seconds = seconds, seconds > 0 {
        let timeoutResult = semaphore.wait(timeout: .now() + seconds)
        switch timeoutResult {
        case .success:
            break
        case .timedOut:
            result = timeout()
        }
    } else {
        semaphore.wait()
    }

    return result
}
