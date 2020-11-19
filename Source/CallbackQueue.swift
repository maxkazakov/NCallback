import Foundation

public enum CallbackQueue: Equatable {
    case absent
    case sync(DispatchCallbackQueue)
    case async(DispatchCallbackQueue)
    case asyncAfter(deadline: DispatchTime, DispatchCallbackQueue)

    public static func == (lhs: CallbackQueue, rhs: CallbackQueue) -> Bool {
        switch (lhs, rhs) {
        case (.absent, .absent):
            return true
        case (.sync(let a), .sync(let b)),
             (.async(let a), .async(let b)):
            return a === b
        case (.asyncAfter(let a1, let a2), .asyncAfter(let b1, let b2)):
            return a1 == b1 && a2 === b2
        case (.absent, _),
             (.sync, _),
             (.async, _),
             (.asyncAfter, _):
            return false
        }
    }

    public static let `default`: CallbackQueue = .async(DispatchQueue.main)
}

public protocol DispatchCallbackQueue: class {
    func async(_ workItem: @escaping () -> Void)
    func sync(_ workItem: () -> Void)
    func asyncAfter(_ deadline: DispatchTime, execute: @escaping () -> Void)
}

extension DispatchQueue: DispatchCallbackQueue {
    public func async(_ workItem: @escaping () -> Void) {
        async(execute: workItem)
    }

    public func sync(_ workItem: () -> Void) {
        sync(execute: workItem)
    }

    public func asyncAfter(_ deadline: DispatchTime, execute: @escaping () -> Void) {
        asyncAfter(deadline: deadline, execute: execute)
    }
}

extension CallbackQueue {
    func fire(_ workItem: @escaping () -> Void) {
        switch self {
        case .absent:
            workItem()
        case .async(let queue):
            queue.async(workItem)
        case .sync(let queue):
            queue.sync(workItem)
        case .asyncAfter(let deadline, let queue):
            queue.asyncAfter(deadline, execute: workItem)
        }
    }
}
