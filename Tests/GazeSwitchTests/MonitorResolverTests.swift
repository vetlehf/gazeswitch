import XCTest
@testable import GazeSwitch

final class MonitorResolverTests: XCTestCase {
    func testResolvesTwoMonitors_leftGaze() {
        let calibration = CalibrationData(
            monitors: [
                MonitorCalibration(screenID: 1, gazeCenter: GazeSignal(pupilRatio: 0.3, yaw: -0.3), screenCenter: CGPoint(x: 960, y: 540)),
                MonitorCalibration(screenID: 2, gazeCenter: GazeSignal(pupilRatio: 0.7, yaw: 0.3), screenCenter: CGPoint(x: 2880, y: 540))
            ],
            boundaries: [0.5]
        )
        let resolver = MonitorResolver(calibration: calibration)
        let gazeLeft = GazeSignal(pupilRatio: 0.65, yaw: 0.25)
        let resolved = resolver.resolve(gazeLeft)
        XCTAssertEqual(resolved?.screenID, 2)
    }

    func testResolvesTwoMonitors_rightGaze() {
        let calibration = CalibrationData(
            monitors: [
                MonitorCalibration(screenID: 1, gazeCenter: GazeSignal(pupilRatio: 0.3, yaw: -0.3), screenCenter: CGPoint(x: 960, y: 540)),
                MonitorCalibration(screenID: 2, gazeCenter: GazeSignal(pupilRatio: 0.7, yaw: 0.3), screenCenter: CGPoint(x: 2880, y: 540))
            ],
            boundaries: [0.5]
        )
        let resolver = MonitorResolver(calibration: calibration)
        let gazeRight = GazeSignal(pupilRatio: 0.35, yaw: -0.25)
        let resolved = resolver.resolve(gazeRight)
        XCTAssertEqual(resolved?.screenID, 1)
    }

    func testResolvesEmptyCalibration_returnsNil() {
        let calibration = CalibrationData(monitors: [], boundaries: [])
        let resolver = MonitorResolver(calibration: calibration)
        let gaze = GazeSignal(pupilRatio: 0.5, yaw: 0.0)
        XCTAssertNil(resolver.resolve(gaze))
    }
}
