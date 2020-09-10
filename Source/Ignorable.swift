import Foundation

@available(*, deprecated, message: "use just 'Ignorable'")
public typealias IgnorableResult = Ignorable

public struct Ignorable: Equatable {
    public init() { }
    public init<T>(_ result: T) { }
}
