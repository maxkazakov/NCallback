import Foundation
import UIKit

import Quick
import Nimble
import NSpry

@testable import NCallback
@testable import NCallbackTestHelpers

class Callback_IgnorableSpec: QuickSpec {
    private enum TestError: Error {
        case case1
        case case2
    }

    override func spec() {
        describe("Callback+Ignorable") {
            describe("Simple Callback") {
                describe("complete") {
                    var subject: Callback<Ignorable>!
                    var result: Ignorable!

                    beforeEach {
                        subject = .init()
                        subject.onComplete {
                            result = $0
                        }

                        subject.complete()
                    }

                    it("should receive result") {
                        expect(result).toNot(beNil())
                    }
                }

                describe("complete") {
                    var subject: Callback<Int>!
                    var mapped: Callback<Ignorable>!
                    var mappedResult: Ignorable!
                    var result: Int!

                    beforeEach {
                        subject = .init()
                        subject.onComplete {
                            result = $0
                        }

                        mapped = subject.flatMapIgnorable()
                        mapped.onComplete {
                            mappedResult = $0
                        }

                        subject.complete(1)
                    }

                    it("should receive result") {
                        expect(result) == 1
                        expect(mappedResult).toNot(beNil())
                    }
                }
            }

            describe("ResultCallback") {
                describe("complete") {
                    var subject: ResultCallback<Ignorable, TestError>!
                    var result: Result<Ignorable, TestError>!

                    beforeEach {
                        subject = .init()
                        subject.onComplete {
                            result = $0
                        }

                        subject.completeSuccessfully()
                    }

                    it("should receive result") {
                        expect(result) == .success(.testMake())
                    }
                }

                describe("complete") {
                    var subject: ResultCallback<Int, TestError>!
                    var mapped: ResultCallback<Ignorable, TestError>!
                    var mappedResult: Result<Ignorable, TestError>!
                    var result: Result<Int, TestError>!

                    beforeEach {
                        subject = .init()
                        subject.onComplete {
                            result = $0
                        }

                        mapped = subject.mapIgnorable()
                        mapped.onComplete {
                            mappedResult = $0
                        }
                    }

                    context("when completed successfully") {
                        beforeEach {
                            subject.complete(1)
                        }

                        it("should receive result") {
                            expect(result) == .success(1)
                            expect(mappedResult) == .success(.testMake())
                        }
                    }

                    context("when completed unsuccessfully") {
                        beforeEach {
                            subject.complete(.case1)
                        }

                        it("should receive result") {
                            expect(result) == .failure(.case1)
                            expect(mappedResult) == .failure(.case1)
                        }
                    }
                }
            }
        }
    }
}
