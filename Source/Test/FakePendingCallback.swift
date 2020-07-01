import Foundation
import Spry

@testable import NCallback

typealias FakeResultPendingCallback<Response, Error: Swift.Error> = FakePendingCallback<Result<Response, Error>>

final
class FakePendingCallback<Response>: PendingCallback<Response>, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case current = "current()"
    }

    var closure: ServiceClosure?
    override func current(_ closure: @escaping ServiceClosure = { _ in }) -> Callback {
        self.closure = closure
        return spryify()
    }
}
