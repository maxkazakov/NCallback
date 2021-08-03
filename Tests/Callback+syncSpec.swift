import Foundation
import UIKit
import NQueue

import Quick
import Nimble
import NSpry

@testable import NCallback
@testable import NCallbackTestHelpers

final class Callback_syncSpec: QuickSpec {
    override func spec() {
        describe("Callback+sync") {
            var result: Int!
            var subject: CallbackWrapper<Int>!

            beforeEach {
                subject = .init()
            }

            afterEach {
                subject = nil
            }

            it("should not start yet") {
                expect(subject.started) == 0
            }

            context("when timeout is absent") {
                var startDate: Date!
                var fireDate: Date!
                var endDate: Date!

                beforeEach {
                    startDate = .init()
                    Queue.background.asyncAfter(deadline: .now() + 1) {
                        fireDate = .init()
                        subject.complete(1)
                    }

                    result = sync(subject.real, timeout: -1)
                    endDate = .init()
                }

                it("should receive result") {
                    expect(result) == 1

                    expect(startDate.timeIntervalSinceReferenceDate).toNot(beCloseTo(endDate.timeIntervalSinceReferenceDate))
                    expect(fireDate.timeIntervalSinceReferenceDate).to(beCloseTo(endDate.timeIntervalSinceReferenceDate, within: 0.25))
                }
            }
        }
    }
}
