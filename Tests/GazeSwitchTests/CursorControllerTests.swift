import XCTest
@testable import GazeSwitch

final class CursorControllerTests: XCTestCase {
    func testNsPointToCGPoint_convertsCoordinates() {
        let primaryHeight: CGFloat = 1080.0
        let nsPoint = NSPoint(x: 500, y: 800)
        let cgPoint = CursorController.nsPointToCGPoint(nsPoint, primaryScreenHeight: primaryHeight)
        XCTAssertEqual(cgPoint.x, 500, accuracy: 0.01)
        XCTAssertEqual(cgPoint.y, 280, accuracy: 0.01)
    }

    func testScreenCenter_calculatesCorrectCGPoint() {
        let primaryHeight: CGFloat = 1440.0
        let frame = CGRect(x: 2560, y: 0, width: 2560, height: 1440)
        let center = CursorController.screenCenter(frame: frame, primaryScreenHeight: primaryHeight)
        XCTAssertEqual(center.x, 3840, accuracy: 0.01)
        XCTAssertEqual(center.y, 720, accuracy: 0.01)
    }
}
