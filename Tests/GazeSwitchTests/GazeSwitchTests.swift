import XCTest
@testable import GazeSwitch

final class GazeSwitchTests: XCTestCase {
    func testGazeSignalClamped01() {
        XCTAssertEqual((-0.5).clamped01(), 0.0)
        XCTAssertEqual((0.5).clamped01(), 0.5)
        XCTAssertEqual((1.5).clamped01(), 1.0)
    }
}
