import XCTest
import FixtureFramework

class FlashExperimentTests: XCTestCase {
    func testExample() throws {
        let sut = FlashExperiment()
        XCTAssertTrue(sut.isAwesome, "Your flash experiment isn't awesome!")
    }
}
