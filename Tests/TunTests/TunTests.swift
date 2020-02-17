import XCTest
@testable import Tun

final class TunTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Tun().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
