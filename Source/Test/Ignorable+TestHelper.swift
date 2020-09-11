import Foundation
import Spry

@testable import NCallback

extension Ignorable: SpryEquatable {
    static func testMake() -> Self {
        .init()
    }

    static func testMake<T>(_: T) -> Self {
        .init()
    }
}
