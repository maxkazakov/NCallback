import Foundation

public protocol CallbackQueue {
    func async(_ workItem: @escaping () -> Void)
    func asyncAfter(_ deadline: DispatchTime, execute: @escaping () -> Void)
}

extension DispatchQueue: CallbackQueue {
    public func async(_ workItem: @escaping () -> Void) {
        async(execute: workItem)
    }

    public func asyncAfter(_ deadline: DispatchTime, execute: @escaping () -> Void) {
        asyncAfter(deadline: deadline, execute: execute)
    }
}
