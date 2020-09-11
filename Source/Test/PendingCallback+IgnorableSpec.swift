import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NCallback
@testable import NCallbackTestHelpers

class PendingCallback_IgnorableSpec: QuickSpec {
    private enum TestError: Error {
        case case1
        case case2
    }

    override func spec() {
        describe("PendingCallback+Ignorable") {
            describe("Simple PendingCallback") {
                describe("complete") {
                    var subject: PendingCallback<Ignorable>!
                    var result: [Ignorable]!

                    beforeEach {
                        result = []

                        subject = .init()

                        for _ in 0..<5 {
                            subject.current().onComplete {
                                result.append($0)
                            }
                        }

                        subject.complete()
                    }

                    it("should receive result") {
                        expect(result).to(equal(.init(repeating: .testMake(), count: 5)))
                    }
                }
            }

            describe("PendingResultCallback") {
                describe("completeSuccessfully") {
                    var subject: PendingResultCallback<Ignorable, TestError>!
                    var result: [Result<Ignorable, TestError>]!

                    beforeEach {
                        result = []

                        subject = .init()

                        for _ in 0..<5 {
                            subject.current().onComplete {
                                result.append($0)
                            }
                        }

                        subject.completeSuccessfully()
                    }

                    it("should receive result") {
                        expect(result).to(equal(.init(repeating: .success(.testMake()), count: 5)))
                    }
                }

                describe("complete with error") {
                    var subject: PendingResultCallback<Ignorable, TestError>!
                    var result: [Result<Ignorable, TestError>]!

                    beforeEach {
                        result = []

                        subject = .init()

                        for _ in 0..<5 {
                            subject.current().onComplete {
                                result.append($0)
                            }
                        }

                        subject.complete(.case1)
                    }

                    it("should receive result") {
                        expect(result).to(equal(.init(repeating: .failure(.case1), count: 5)))
                    }
                }

                describe("complete with error") {
                    var subject: PendingResultCallback<Int, TestError>!
                    var result: [Result<Int, TestError>]!

                    beforeEach {
                        result = []

                        subject = .init()

                        for _ in 0..<5 {
                            subject.current().onComplete {
                                result.append($0)
                            }
                        }

                        subject.complete(1)
                    }

                    it("should receive result") {
                        expect(result).to(equal(.init(repeating: .success(1), count: 5)))
                    }
                }
            }
        }
    }
}
