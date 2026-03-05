import XCTest
@testable import GazeSwitch

final class CalibrationDataTests: XCTestCase {
    func testCalibrationDataEncodeDecode() throws {
        let monitor = MonitorCalibration(
            screenID: 1,
            gazeCenter: GazeSignal(pupilRatio: 0.35, yaw: -0.15),
            screenCenter: CGPoint(x: 1280, y: 720)
        )
        let data = CalibrationData(
            monitors: [monitor],
            boundaries: [0.5]
        )

        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(CalibrationData.self, from: encoded)

        XCTAssertEqual(decoded.monitors.count, 1)
        XCTAssertEqual(decoded.monitors[0].screenID, 1)
        XCTAssertEqual(decoded.monitors[0].gazeCenter.pupilRatio, 0.35, accuracy: 0.001)
        XCTAssertEqual(decoded.monitors[0].gazeCenter.yaw, -0.15, accuracy: 0.001)
        XCTAssertEqual(decoded.boundaries, [0.5])
    }

    func testGazeSignalCombinedScore() {
        let signal = GazeSignal(pupilRatio: 0.3, yaw: -0.2)
        let score = signal.combinedScore()
        XCTAssertGreaterThan(score, 0.0)
        XCTAssertLessThan(score, 1.0)
    }
}
