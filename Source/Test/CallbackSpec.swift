import Foundation
import UIKit

import Quick
import Nimble
import Spry

@testable import NCallback
@testable import NCallbackTestHelpers

private final class SubjectWrapper<Value> {
    private(set) weak var weakValue: Callback<Value>?
    var value: Callback<Value>!
    var stopped: Bool = false
    var started: Bool {
        action != nil
    }

    func set(_ value: Callback<Value>?) {
        self.value = value
        self.weakValue = value
    }

    private(set) var action: ((Value) -> Void)?
    lazy var start: (Callback<Value>) -> Void = { [weak self] original in
        let original = original
        self?.action = { [weak original] value in
            original?.complete(value)
        }
    }

    lazy var stop: (Callback<Value>) -> Void = { [weak self] original in
        self?.stopped = true
    }

    func onComplete(options: CallbackOption = .default,
                    _ callback: @escaping Callback<Value>.Completion) {
        value.onComplete(options: options, callback)
    }
}

class CallbackSpec: QuickSpec {
    private enum Constant {
        static let deffered = "shared callback with `start` service"
    }

    override func spec() {
        fdescribe("Callback") {
            var wrapper: SubjectWrapper<Int>!
            var subject: Callback<Int>! {
                get {
                    wrapper.value
                }
                set {
                    wrapper.set(newValue)
                }
            }

            beforeEach {
                wrapper = .init()
            }

            describe("empty init") {
                beforeEach {
                    subject = .init()
                }

                context("when configured twice") {
                    beforeEach {
                        subject.onComplete({ _ in })
                    }

                    it("should throw assert") {
                        expect { subject.onComplete({ _ in }) }.to(throwAssertion())
                    }
                }

                describe("flatMap") {
                    var result: Bool!
                    var originalResult: Int!
                    var mapped: Callback<Bool>!

                    beforeEach {
                        subject.onComplete({ originalResult = $0 })
                        mapped = subject.flatMap({ $0 > 0 })
                        mapped.onComplete({ result = $0 })
                    }

                    it("should be other instance") {
                        expect(mapped).toNot(be(subject))
                    }

                    context("when original value is 0") {
                        beforeEach {
                            subject.complete(0)
                        }

                        it("should be receive mapped result") {
                            expect(result).to(beFalse())
                        }

                        it("should be receive original result") {
                            expect(originalResult).to(equal(0))
                        }
                    }

                    context("when original value is less then 0") {
                        beforeEach {
                            subject.complete(-1)
                        }

                        it("should be receive mapped result") {
                            expect(result).to(beFalse())
                        }

                        it("should be receive original result") {
                            expect(originalResult).to(equal(-1))
                        }
                    }

                    context("when original value is greater then 0") {
                        beforeEach {
                            subject.complete(1)
                        }

                        it("should be receive mapped result") {
                            expect(result).to(beTrue())
                        }

                        it("should be receive original result") {
                            expect(originalResult).to(equal(1))
                        }
                    }
                }
            }

            sharedExamples(Constant.deffered) {
                describe("flatMap") {
                    var result: Bool!
                    var originalResult: Int!
                    var mapped: Callback<Bool>!

                    context("when original value is greater then 0") {
                        beforeEach {
                            subject.onComplete({ originalResult = $0 })
                            mapped = subject.flatMap({ $0 > 0 })
                            mapped.onComplete({ result = $0 })

                            wrapper.action?(1)
                        }

                        it("should be other instance") {
                            expect(mapped).toNot(be(subject))
                        }

                        it("should be receive original result") {
                            expect(originalResult).to(equal(1))
                        }

                        it("should be receive mapped result") {
                            expect(result).to(beTrue())
                        }
                    }

                    context("when original value is greater then 0") {
                        beforeEach {
                            subject.onComplete({ originalResult = $0 })
                            mapped = subject.flatMap({ $0 < 0 })
                            mapped.onComplete({ result = $0 })

                            wrapper.action?(1)
                        }

                        it("should be other instance") {
                            expect(mapped).toNot(be(subject))
                        }

                        it("should be receive original result") {
                            expect(originalResult).to(equal(1))
                        }

                        it("should be receive mapped result") {
                            expect(result).to(beFalse())
                        }
                    }
                }
            }

            describe("init with deferred autoclosure result") {
                beforeEach {
                    subject = .init(result: 1)
                }

                context("when configured twice") {
                    beforeEach {
                        subject.onComplete({ _ in })
                    }

                    it("should throw assert") {
                        expect { subject.onComplete({ _ in }) }.to(throwAssertion())
                    }
                }

                itBehavesLike(Constant.deffered)
            }

            describe("init with deferred result") {
                beforeEach {
                    subject = .init(result: { return 1 })
                }

                context("when configured twice") {
                    beforeEach {
                        subject.onComplete({ _ in })
                    }

                    it("should throw assert") {
                        expect { subject.onComplete({ _ in }) }.to(throwAssertion())
                    }
                }

                itBehavesLike(Constant.deffered)
            }

            describe("init with deferred result and cancel action") {
                beforeEach {
                    subject = .init(start: wrapper.start,
                                    stop: wrapper.stop)
                }

                afterEach {
                    wrapper.stopped = false
                }

                context("when configured for the second time") {
                    beforeEach {
                        subject.onComplete({ _ in })
                    }

                    it("should throw assert") {
                        expect { subject.onComplete({ _ in }) }.to(throwAssertion())
                    }

                    context("when canceled") {
                        beforeEach {
                            subject.cancel()
                        }

                        it("should call stop on deinit") {
                            expect(wrapper.stopped).to(beTrue())
                        }
                    }

                    context("when self retained; when configuring for the third time") {
                        weak var saved: Callback<Int>?

                        beforeEach {
                            subject.cancel()
                            subject.onComplete(options: .selfRetained, { _ in  })

                            saved = subject
                            subject = nil
                        }

                        it("should contains reference") {
                            expect(saved).toNot(beNil())
                        }
                    }
                }

                itBehavesLike(Constant.deffered)

                describe("deinit") {
                    beforeEach {
                        subject = nil
                    }

                    it("should call stop on deinit") {
                        expect(wrapper.stopped).to(beTrue())
                    }
                }
            }

            describe("lifecycle") {
                var result: Int!

                beforeEach {
                    subject = .init(start: wrapper.start,
                                    stop: wrapper.stop)
                }

                afterEach {
                    wrapper.stopped = false
                    result = nil
                }

                describe("weakness") {
                    beforeEach {
                        subject.onComplete(options: .weakness, { result = $0 })
                    }

                    context("when destructed before completion") {
                        beforeEach {
                            subject = nil
                            wrapper.action?(1)
                        }

                        it("should not receive result") {
                            expect(result).to(beNil())
                        }

                        it("should call stop on deinit") {
                            expect(wrapper.stopped).to(beTrue())
                        }
                    }

                    context("when complete correctly and destructed") {
                        beforeEach {
                            wrapper.action?(1)
                            wrapper.value = nil
                        }

                        it("should receive result") {
                            expect(result).to(equal(1))
                        }

                        it("should call stop on deinit") {
                            expect(wrapper.stopped).to(beTrue())
                        }
                    }
                }

                describe("selfRetained") {
                    beforeEach {
                        subject.onComplete(options: .selfRetained, { result = $0 })
                        subject = nil
                    }

                    context("when cant be destructed before completion") {
                        beforeEach {
                            wrapper.stopped = false
                        }

                        it("should not receive result") {
                            expect(result).to(beNil())
                        }

                        it("should not call stop") {
                            expect(wrapper.stopped).to(beFalse())
                        }

                        context("when complete correctly and destructed") {
                            beforeEach {
                                wrapper.action?(2)
                            }

                            it("should receive result") {
                                expect(result).to(equal(2))
                            }

                            it("should call stop on deinit") {
                                expect(wrapper.stopped).to(beTrue())
                            }
                        }
                    }

                    context("when complete correctly and destructed") {
                        beforeEach {
                            wrapper.stopped = false
                            wrapper.action?(1)
                        }

                        it("should receive result") {
                            expect(result).to(equal(1))
                        }

                        it("should call stop on deinit") {
                            expect(wrapper.stopped).to(beTrue())
                        }
                    }
                }

                describe("repeatable") {
                    beforeEach {
                        subject.onComplete(options: .repeatable, { result = $0 })
                    }

                    context("when destructed before completion") {
                        beforeEach {
                            wrapper.stopped = false
                            subject = nil
                            wrapper.action?(1)
                        }

                        it("should not receive result") {
                            expect(result).to(beNil())
                        }

                        it("should call stop on deinit") {
                            expect(wrapper.stopped).to(beTrue())
                        }
                    }

                    context("when complete correctly and destructed") {
                        beforeEach {
                            wrapper.stopped = false
                            wrapper.action?(1)
                        }

                        it("should receive result") {
                            expect(result).to(equal(1))
                        }

                        it("should not call stop") {
                            expect(wrapper.stopped).to(beFalse())
                        }

                        context("when completed twice") {
                            beforeEach {
                                wrapper.stopped = false
                                wrapper.action?(2)
                            }

                            it("should receive result") {
                                expect(result).to(equal(2))
                            }

                            it("should not call stop") {
                                expect(wrapper.stopped).to(beFalse())
                            }

                            context("when destructed before") {
                                beforeEach {
                                    wrapper.stopped = false
                                    result = nil
                                    subject = nil
                                    wrapper.action?(1)
                                }

                                it("should not receive result") {
                                    expect(result).to(beNil())
                                }

                                it("should call stop on deinit") {
                                    expect(wrapper.stopped).to(beTrue())
                                }
                            }
                        }
                    }
                }

                describe("oneWay") {
                    beforeEach {
                        subject.oneWay(options: .selfRetained)
                    }

                    context("when cant be destructed before completion") {
                        beforeEach {
                            wrapper.stopped = false
                            subject = nil
                        }

                        it("should not receive result") {
                            expect(result).to(beNil())
                        }

                        it("should not call stop") {
                            expect(wrapper.stopped).to(beFalse())
                        }

                        context("when complete correctly and destructed") {
                            beforeEach {
                                wrapper.action?(2)
                            }

                            it("should receive result") {
                                expect(result).to(beNil())
                            }

                            it("should call stop on deinit") {
                                expect(wrapper.stopped).to(beTrue())
                            }
                        }
                    }

                    context("when complete correctly and destructed") {
                        beforeEach {
                            wrapper.stopped = false
                            subject = nil
                            wrapper.action?(1)
                        }

                        it("should receive result") {
                            expect(result).to(beNil())
                        }

                        it("should call stop on deinit") {
                            expect(wrapper.stopped).to(beTrue())
                        }
                    }
                }

                describe("beforeComplete and deferred") {
                    enum Events: Hashable {
                        case beforeComplete
                        case onComplete
                        case deferred
                    }
                    var events: [Events]!

                    beforeEach {
                        events = []

                        subject.onComplete({ _ in events.append(.onComplete) })
                        subject.beforeComplete({ _ in events.append(.beforeComplete) })
                        subject.deferred({ _ in events.append(.deferred) })

                        wrapper.action?(1)
                    }

                    it("should resolve events in correct order") {
                        let expected: [Events] = [.beforeComplete, .onComplete, .deferred]
                        expect(events).to(equal(expected))
                    }
                }

                describe("Hashable") {
                    var subject2: Callback<Int>!

                    beforeEach {
                        subject2 = .init()
                    }

                    context("when hashing by ref") {
                        beforeEach {
                            subject.hashKey = nil
                            subject2.hashKey = nil
                        }

                        it("should not equal") {
                            expect(subject).toNot(equal(subject2))
                        }

                        it("should generate different hashes") {
                            expect(subject.hashValue).toNot(equal(subject2.hashValue))
                        }
                    }

                    context("when hashing both by hashKey") {
                        beforeEach {
                            subject.hashKey = "123"
                            subject2.hashKey = "123"
                        }

                        it("should be equal") {
                            expect(subject).to(equal(subject2))
                        }

                        it("should generate same hashes") {
                            expect(subject.hashValue).to(equal(subject2.hashValue))
                        }
                    }

                    context("when hashing the first by hashKey") {
                        beforeEach {
                            subject.hashKey = "123"
                            subject2.hashKey = nil
                        }

                        it("should not equal") {
                            expect(subject).toNot(equal(subject2))
                        }

                        it("should generate different hashes") {
                            expect(subject.hashValue).toNot(equal(subject2.hashValue))
                        }
                    }

                    context("when hashing the second by hashKey") {
                        beforeEach {
                            subject.hashKey = nil
                            subject2.hashKey = "123"
                        }

                        it("should not equal") {
                            expect(subject).toNot(equal(subject2))
                        }

                        it("should generate different hashes") {
                            expect(subject.hashValue).toNot(equal(subject2.hashValue))
                        }
                    }
                }

                describe("zip") {
                    var result: (Int, Bool)!
                    var wrapper2: SubjectWrapper<Bool>!
                    var subject2: Callback<Bool>! {
                        get {
                            wrapper2.value
                        }
                        set {
                            wrapper2.set(newValue)
                        }
                    }

                    var zipped: Callback<(Int, Bool)>!

                    beforeEach {
                        wrapper2 = .init()
                        subject2 = .init(start: wrapper2.start,
                                         stop: wrapper2.stop)

                        zipped = zip(subject, subject2)
                    }

                    it("should not start yet") {
                        expect(wrapper.started).to(beFalse())
                        expect(wrapper2.started).to(beFalse())
                    }

                    context("when started") {
                        beforeEach {
                            zipped.onComplete(options: .selfRetained) {
                                result = $0
                            }
                        }

                        afterEach {
                            result = nil
                        }

                        it("should not start yet") {
                            expect(wrapper.started).to(beTrue())
                            expect(wrapper2.started).to(beTrue())
                        }

                        it("should not receive result") {
                            expect(result).to(beNil())
                        }

                        context("when resolved the first") {
                            beforeEach {
                                wrapper.action?(1)
                            }

                            it("should not receive result") {
                                expect(result).to(beNil())
                            }

                            context("when resolved the second") {
                                beforeEach {
                                    wrapper2.action?(true)
                                }

                                it("should receive result") {
                                    expect(result.0).to(equal(1))
                                    expect(result.1).to(beTrue())
                                }
                            }
                        }

                        context("when resolved the second") {
                            beforeEach {
                                wrapper2.action?(true)
                            }

                            it("should not receive result") {
                                expect(result).to(beNil())
                            }

                            context("when resolved the first") {
                                beforeEach {
                                    wrapper.action?(2)
                                }

                                it("should receive result") {
                                    expect(result.0).to(equal(2))
                                    expect(result.1).to(beTrue())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
