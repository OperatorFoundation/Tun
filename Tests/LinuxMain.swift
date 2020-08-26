import XCTest

import TunTests

var tests = [XCTestCaseEntry]()
tests += TunTests.allTests() //FIXME: allTests() is not available on linux...
XCTMain(tests)
