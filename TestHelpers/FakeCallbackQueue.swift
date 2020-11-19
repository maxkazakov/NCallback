import Foundation
import Spry

@testable import NCallback

final
public class FakeDispatchCallbackQueue: DispatchCallbackQueue, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case async = "async(_:)"
        case sync = "sync(_:)"
        case asyncAfter = "asyncAfter(_:execute:)"
    }

    public var shouldFireClosures: Bool = false
    public func async(_ workItem: @escaping () -> Void) {
        if shouldFireClosures {
            workItem()
        }

        asyncWorkItem = workItem
        return spryify(arguments: workItem)
    }

    public func sync(_ workItem: () -> Void) {
        if shouldFireClosures {
            workItem()
        }

        return spryify()
    }

    var asyncWorkItem: (() -> Void)?
    public func asyncAfter(_ deadline: DispatchTime, execute workItem: @escaping () -> Void) {
        if shouldFireClosures {
            workItem()
        }

        asyncWorkItem = workItem
        return spryify(arguments: deadline, workItem)
    }
}

extension CallbackQueue: SpryEquatable {
}

extension DispatchTime: SpryEquatable {
}
