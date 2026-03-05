import Foundation
import Vision

enum GazeEstimator {
    static func estimate(
        leftPupilCenter: CGPoint,
        leftEyeLeftCorner: CGPoint,
        leftEyeRightCorner: CGPoint,
        headYaw: Double
    ) -> GazeSignal {
        let eyeWidth = leftEyeRightCorner.x - leftEyeLeftCorner.x
        let pupilRatio: Double
        if eyeWidth > 0.001 {
            pupilRatio = Double(
                (leftPupilCenter.x - leftEyeLeftCorner.x) / eyeWidth
            )
        } else {
            pupilRatio = 0.5
        }

        return GazeSignal(
            pupilRatio: min(max(pupilRatio, 0.0), 1.0),
            yaw: headYaw
        )
    }

    static func estimate(from observation: VNFaceObservation) -> GazeSignal? {
        guard let landmarks = observation.landmarks,
              let leftPupil = landmarks.leftPupil, leftPupil.pointCount > 0,
              let leftEye = landmarks.leftEye, leftEye.pointCount >= 2 else {
            return nil
        }

        let pupilCenter = leftPupil.normalizedPoints[0]
        let eyePoints = (0..<leftEye.pointCount).map { leftEye.normalizedPoints[$0] }
        let leftCorner = eyePoints.min(by: { $0.x < $1.x }) ?? CGPoint(x: 0, y: 0.5)
        let rightCorner = eyePoints.max(by: { $0.x < $1.x }) ?? CGPoint(x: 1, y: 0.5)
        let yaw = observation.yaw?.doubleValue ?? 0.0

        return estimate(
            leftPupilCenter: pupilCenter,
            leftEyeLeftCorner: leftCorner,
            leftEyeRightCorner: rightCorner,
            headYaw: yaw
        )
    }
}
