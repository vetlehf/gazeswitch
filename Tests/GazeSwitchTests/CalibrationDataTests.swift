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

    func testCalibrationDataWithGazePoints_encodeDecode() throws {
        let points: [CalibrationPoint] = [
            CalibrationPoint(position: .center, signal: GazeSignal(pupilRatio: 0.5, yaw: 0.0)),
            CalibrationPoint(position: .topLeft, signal: GazeSignal(pupilRatio: 0.3, yaw: -0.2)),
            CalibrationPoint(position: .topRight, signal: GazeSignal(pupilRatio: 0.3, yaw: 0.2)),
            CalibrationPoint(position: .bottomLeft, signal: GazeSignal(pupilRatio: 0.7, yaw: -0.2)),
            CalibrationPoint(position: .bottomRight, signal: GazeSignal(pupilRatio: 0.7, yaw: 0.2)),
        ]
        let monitor = MonitorCalibration(
            screenID: 1,
            gazeCenter: GazeSignal(pupilRatio: 0.5, yaw: 0.0),
            screenCenter: CGPoint(x: 960, y: 540),
            gazePoints: points
        )
        let data = CalibrationData(monitors: [monitor], boundaries: [])
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(CalibrationData.self, from: encoded)
        XCTAssertEqual(decoded.monitors[0].gazePoints.count, 5)
        XCTAssertEqual(decoded.monitors[0].gazePoints[0].position, .center)
    }

    func testScoreRange_withGazePoints() {
        let points: [CalibrationPoint] = [
            CalibrationPoint(position: .topLeft, signal: GazeSignal(pupilRatio: 0.2, yaw: -0.4)),
            CalibrationPoint(position: .bottomRight, signal: GazeSignal(pupilRatio: 0.8, yaw: 0.4)),
        ]
        let monitor = MonitorCalibration(
            screenID: 1,
            gazeCenter: GazeSignal(pupilRatio: 0.5, yaw: 0.0),
            screenCenter: .zero,
            gazePoints: points
        )
        let range = monitor.scoreRange
        XCTAssertNotNil(range)
        XCTAssertLessThan(range!.lowerBound, range!.upperBound)
    }

    func testScoreRange_emptyGazePoints_returnsNil() {
        let monitor = MonitorCalibration(
            screenID: 1,
            gazeCenter: GazeSignal(pupilRatio: 0.5, yaw: 0.0),
            screenCenter: .zero
        )
        XCTAssertNil(monitor.scoreRange)
    }

    func testBackwardCompatibility_oldDataDecodes() throws {
        let json = """
        {"screenID":1,"gazeCenter":{"pupilRatio":0.5,"yaw":0.0},"screenCenter":[960,540]}
        """
        let decoded = try JSONDecoder().decode(MonitorCalibration.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.gazePoints, [])
        XCTAssertEqual(decoded.screenID, 1)
    }
}
