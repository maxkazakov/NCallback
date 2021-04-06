import Foundation

final
class UnfairLock {
    private var unfairLock = os_unfair_lock_s()

    func tryLock() -> Bool {
        os_unfair_lock_trylock(&unfairLock)
    }

    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }
}
