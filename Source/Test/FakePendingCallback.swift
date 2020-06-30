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

    convenience init() {
        self.init(generator: { fatalError("must be stubbed") })
    }

    override func current() -> Callback<Response> {
        return spryify()
    }
}
