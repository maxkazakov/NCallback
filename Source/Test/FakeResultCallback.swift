import Foundation
import Spry

@testable import NCallback

typealias FakeResultCallback<Response, Error: Swift.Error> = FakeCallback<Result<Response, Error>>
