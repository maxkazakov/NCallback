import XCTest
import Quick

QCKMain([
    Callback_IgnorableSpec.self,
    CallbackSpec.self,
    IgnorableSpec.self,
    PendingCallback_IgnorableSpec.self,
    PendingCallbackSpec.self
])
