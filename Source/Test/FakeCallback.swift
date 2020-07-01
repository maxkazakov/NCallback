import Foundation
import Spry

@testable import NCallback

final
class FakeCallback<Response>: Callback<Response>, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case onComplete = "onComplete(kind:_:)"
        case complete = "complete(kind:_:)"
        case cancel = "cancel()"

        case flatMap = "flatMap(_:)"
    }

    var onComplete: Completion?
    override public func onComplete(options: CallbackOption = .default, _ callback: @escaping Completion) {
        self.onComplete = callback
        return spryify(arguments: options, callback)
    }

    override func complete(_ result: Response) {
        return spryify(arguments: result)
    }

    override func cancel() {
        return spryify()
    }

    override func flatMap<NewResponse>(_ mapper: @escaping (Response) -> NewResponse) -> Callback<NewResponse> {
        return spryify(arguments: mapper)
    }
}
