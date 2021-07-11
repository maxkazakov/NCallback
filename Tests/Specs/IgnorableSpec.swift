import Foundation
import UIKit

import Quick
import Nimble
import NSpry

@testable import NCallback
@testable import NCallbackTestHelpers

class IgnorableSpec: QuickSpec {
    override func spec() {
        describe("Ignorable") {
            it("should make instance from empty init") {
                expect(Ignorable()).toNot(beNil())
            }

            it("should make instance from generic init") {
                expect(Ignorable(1)).toNot(beNil())
            }
        }
    }
}
