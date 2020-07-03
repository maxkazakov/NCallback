import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NCallback
@testable import NCallbackTestHelpers

class PendingCallbackSpec: QuickSpec {
    private enum Constant {
        static let sharedBehavior = "PendingCallback Behavior"
        static let sharedInitialState = "PendingCallback Initial State"
    }

    override func spec() {
        describe("PendingCallback") {
            var callback: FakeCallback<Int>!
            var subject: PendingCallback<Int>!

            beforeEach {
                callback = .init()
            }

            sharedExamples(Constant.sharedInitialState) {
                it("should be clear") {
                    expect(subject.isPending).to(beFalse())
                }

                context("when no pending callbacks") {
                    context("when canceling") {
                        it("should throw assertion") {
                            expect { subject.cancel() }.to(throwAssertion())
                        }
                    }

                    context("when completing") {
                        it("should throw assertion") {
                            expect { subject.complete(1) }.to(throwAssertion())
                        }
                    }
                }
            }

            sharedExamples(Constant.sharedBehavior) {
                context("when requesting the first callback") {
                    var actual: Callback<Int>!
                    var deferred: FakeCallback<Int>!

                    beforeEach {
                        deferred = .init()
                        callback.stub(.deferred).andReturn(deferred)
                        actual = subject.current()
                    }

                    it("should generate new instance") {
                        expect(callback).to(haveReceived(.deferred, with: Argument.anything))
                        expect(actual).to(be(deferred))
                    }

                    it("should be in the pending state") {
                        expect(subject.isPending).to(beTrue())
                    }

                    context("cancel") {
                        beforeEach {
                            callback.stub(.cancel).andReturn()
                            subject.cancel()
                        }

                        it("should cancel cached callback") {
                            expect(callback).to(haveReceived(.cancel))
                        }

                        it("should be clear") {
                            expect(subject.isPending).to(beFalse())
                        }
                    }

                    context("complete") {
                        beforeEach {
                            callback.stub(.complete).andReturn()
                            subject.complete(1)
                        }

                        it("should complete cached callback") {
                            expect(callback).to(haveReceived(.complete, with: 1))
                        }

                        it("should be clear") {
                            expect(subject.isPending).to(beFalse())
                        }
                    }

                    context("when requesting the second callback") {
                        var actual2: Callback<Int>!
                        var closure: Callback<Int>.Completion?
                        var result: Int!

                        beforeEach {
                            callback.stubAgain(.deferred).andDo { args in
                                closure = args[0] as? Callback<Int>.Completion
                                return deferred
                            }
                            actual2 = subject.current()
                            actual2.onComplete({ result = $0 })
                            closure?(2)
                        }

                        it("should generate new instance") {
                            expect(actual2).toNot(be(deferred))
                            expect(actual2).toNot(be(actual))
                            expect(actual2).toNot(be(callback))
                        }

                        it("should receive result") {
                            expect(result).to(equal(2))
                        }
                    }
                }
            }

            describe("generator") {
                beforeEach {
                    subject = .init(generator: { return callback })
                }

                itBehavesLike(Constant.sharedInitialState)
                itBehavesLike(Constant.sharedBehavior)
            }

            describe("autoclosure generator") {
                beforeEach {
                    subject = .init(generator: callback)
                }

                itBehavesLike(Constant.sharedInitialState)
                itBehavesLike(Constant.sharedBehavior)
            }

            describe("autoclosure generator") {
                beforeEach {
                    subject = .init(generator: { _ in callback })
                }

                itBehavesLike(Constant.sharedInitialState)
                itBehavesLike(Constant.sharedBehavior)
            }

            describe("empty init") {
                beforeEach {
                    subject = .init()
                }

                itBehavesLike(Constant.sharedInitialState)

                context("when requesting the first callback") {
                    var actual: Callback<Int>!

                    beforeEach {
                        actual = subject.current()
                    }

                    it("should generate new instance") {
                        expect(actual).toNot(be(callback))
                    }

                    it("should be in the pending state") {
                        expect(subject.isPending).to(beTrue())
                    }

                    context("cancel") {
                        beforeEach {
                            subject.cancel()
                        }

                        it("should be clear") {
                            expect(subject.isPending).to(beFalse())
                        }
                    }

                    context("complete") {
                        var result: Int!

                        beforeEach {
                            actual.onComplete({ result = $0 })
                            subject.complete(1)
                        }

                        it("should receive result") {
                            expect(result).to(equal(1))
                        }

                        it("should be clear") {
                            expect(subject.isPending).to(beFalse())
                        }
                    }
                }
            }
        }
    }
}
