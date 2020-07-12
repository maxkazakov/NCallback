import Foundation

public typealias PendingResultCallback<Response, Error: Swift.Error> = PendingCallback<Result<Response, Error>>

public class PendingCallback<ResultType> {
    public typealias Callback = NCallback.Callback<ResultType>
    public typealias ServiceClosure = Callback.ServiceClosure
    public typealias ServiceGenerator = (@escaping ServiceClosure) -> Callback
    public typealias Generator = () -> Callback

    private let generator: ServiceGenerator
    private var cached: Callback?

    public var isPending: Bool {
        cached != nil
    }

    public convenience init(generator: @escaping Generator) {
        self.init(generator: { _ in generator() } )
    }

    public convenience init(generator: @escaping @autoclosure Generator) {
        self.init(generator: { _ in generator() } )
    }

    public required init(generator: @escaping ServiceGenerator) {
        self.generator = generator
    }

    public convenience init() {
        self.init(generator: { .init(start: $0) } )
    }

    public func current(_ closure: @escaping ServiceClosure = { _ in }) -> Callback {
        let result: Callback
        if let current = cached {
            result = .init()

            _ = current.deferred { [result] in
                result.complete($0)
            }
        } else {
            let generated = generator(closure)
            cached = generated
            result = generated.deferred { [weak self] _ in
                self?.cached = nil
            }
        }

        return result
    }

    public func complete(_ result: ResultType) {
        assert(cached != nil, "no one will receive this event while no subscribers")
        cached?.complete(result)
        cached = nil
    }

    public func cancel() {
        cached?.cancel()
        cached = nil
    }
}
