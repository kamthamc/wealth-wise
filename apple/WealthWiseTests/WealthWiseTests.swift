import XCTestimport XCTestimport XCTest



final class WealthWiseTests: XCTestCase {@testable import WealthWise



    override func setUpWithError() throws {final class WealthWiseTests: XCTestCase {

        // Put setup code here. This method is called before the invocation of each test method in the class.

    }final class WealthWiseTests: XCTestCase {



    override func tearDownWithError() throws {    override func setUpWithError() throws {    

        // Put teardown code here. This method is called after the invocation of each test method in the class.

    }        // Put setup code here. This method is called before the invocation of each test method in the class.    func testExample() throws {



    func testExample() throws {    }        // This is an example of a functional test case.

        // This is an example of a functional test case.

        XCTAssertTrue(true, "This test should always pass")        // Use XCTAssert and related functions to verify your tests produce the correct results.

    }

    override func tearDownWithError() throws {        // Any test you write for XCTest can be annotated as throws and async.

    func testPerformanceExample() throws {

        // This is an example of a performance test case.        // Put teardown code here. This method is called after the invocation of each test method in the class.        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.

        self.measure {

            // Put the code you want to measure the time of here.    }        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.

        }

    }        XCTAssertTrue(true, "This test should always pass")



}    func testExample() throws {    }

        // This is an example of a functional test case.    

        // Use XCTAssert and related functions to verify your tests produce the correct results.    func testPerformanceExample() throws {

        // Any test you write for XCTest can be annotated as throws and async.        // This is an example of a performance test case.

        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.        measure {

        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.            // Put the code you want to measure the time of here.

    }        }

    }

    func testPerformanceExample() throws {}
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}