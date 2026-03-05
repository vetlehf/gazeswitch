import XCTest
@testable import GazeSwitch

final class GazeEstimatorTests: XCTestCase {
    func testEstimateFromLandmarks_centerGaze() {
        let leftPupil = CGPoint(x: 0.5, y: 0.5)
        let leftEyeLeft = CGPoint(x: 0.0, y: 0.5)
        let leftEyeRight = CGPoint(x: 1.0, y: 0.5)
        let yaw: Double = 0.0

        let signal = GazeEstimator.estimate(
            leftPupilCenter: leftPupil,
            leftEyeLeftCorner: leftEyeLeft,
            leftEyeRightCorner: leftEyeRight,
            headYaw: yaw
        )

        XCTAssertEqual(signal.pupilRatio, 0.5, accuracy: 0.01)
        XCTAssertEqual(signal.yaw, 0.0, accuracy: 0.01)
    }

    func testEstimateFromLandmarks_lookingLeft() {
        let leftPupil = CGPoint(x: 0.7, y: 0.5)
        let leftEyeLeft = CGPoint(x: 0.0, y: 0.5)
        let leftEyeRight = CGPoint(x: 1.0, y: 0.5)
        let yaw: Double = 0.3

        let signal = GazeEstimator.estimate(
            leftPupilCenter: leftPupil,
            leftEyeLeftCorner: leftEyeLeft,
            leftEyeRightCorner: leftEyeRight,
            headYaw: yaw
        )

        XCTAssertGreaterThan(signal.pupilRatio, 0.5)
        XCTAssertGreaterThan(signal.yaw, 0.0)
        XCTAssertGreaterThan(signal.combinedScore(), 0.5)
    }

    func testEstimateFromLandmarks_lookingRight() {
        let leftPupil = CGPoint(x: 0.3, y: 0.5)
        let leftEyeLeft = CGPoint(x: 0.0, y: 0.5)
        let leftEyeRight = CGPoint(x: 1.0, y: 0.5)
        let yaw: Double = -0.3

        let signal = GazeEstimator.estimate(
            leftPupilCenter: leftPupil,
            leftEyeLeftCorner: leftEyeLeft,
            leftEyeRightCorner: leftEyeRight,
            headYaw: yaw
        )

        XCTAssertLessThan(signal.pupilRatio, 0.5)
        XCTAssertLessThan(signal.yaw, 0.0)
        XCTAssertLessThan(signal.combinedScore(), 0.5)
    }

    func testEstimateWithZeroWidthEye_returnsCenter() {
        let leftPupil = CGPoint(x: 0.5, y: 0.5)
        let corner = CGPoint(x: 0.5, y: 0.5)

        let signal = GazeEstimator.estimate(
            leftPupilCenter: leftPupil,
            leftEyeLeftCorner: corner,
            leftEyeRightCorner: corner,
            headYaw: 0.0
        )

        XCTAssertEqual(signal.pupilRatio, 0.5, accuracy: 0.01)
    }
}
