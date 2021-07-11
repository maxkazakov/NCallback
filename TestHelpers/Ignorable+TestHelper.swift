import Foundation
import NSpry

@testable import NCallback

extension Ignorable: SpryEquatable {
    static func testMake() -> Self {
        return .init()
    }

    static func testMake<T>(_: T) -> Self {
        return .init()
    }
}
