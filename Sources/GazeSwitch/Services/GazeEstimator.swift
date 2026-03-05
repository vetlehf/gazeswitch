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
            pupilRatio: pupilRatio.clamped01(),
            yaw: headYaw
        )
    }

    static func estimate(
        leftPupilRatio: Double?,
        rightPupilRatio: Double?,
        headYaw: Double
    ) -> GazeSignal? {
        let avgPupilRatio: Double
        switch (leftPupilRatio, rightPupilRatio) {
        case let (.some(l), .some(r)):
            avgPupilRatio = (l + r) / 2.0
        case let (.some(l), .none):
            avgPupilRatio = l
        case let (.none, .some(r)):
            avgPupilRatio = r
        case (.none, .none):
            return nil
        }
        return GazeSignal(
            pupilRatio: avgPupilRatio.clamped01(),
            yaw: headYaw
        )
    }

    static func estimate(from observation: VNFaceObservation) -> GazeSignal? {
        guard let landmarks = observation.landmarks else {
            GazeLog.gaze.debug("No landmarks in face observation")
            return nil
        }

        let yaw = observation.yaw?.doubleValue ?? 0.0

        let leftRatio: Double? = {
            guard let leftPupil = landmarks.leftPupil,
                  let leftEye = landmarks.leftEye else { return nil }
            return pupilRatio(pupilLandmark: leftPupil, eyeLandmark: leftEye)
        }()

        let rightRatio: Double? = {
            guard let rightPupil = landmarks.rightPupil,
                  let rightEye = landmarks.rightEye else { return nil }
            return pupilRatio(pupilLandmark: rightPupil, eyeLandmark: rightEye)
        }()

        let result = estimate(leftPupilRatio: leftRatio, rightPupilRatio: rightRatio, headYaw: yaw)
        if result == nil {
            GazeLog.gaze.debug("No usable pupil landmarks")
        }
        return result
    }

    private static func pupilRatio(
        pupilLandmark: VNFaceLandmarkRegion2D,
        eyeLandmark: VNFaceLandmarkRegion2D
    ) -> Double? {
        guard pupilLandmark.pointCount > 0, eyeLandmark.pointCount >= 2 else {
            return nil
        }
        let pupilCenter = pupilLandmark.normalizedPoints[0]
        var minX: CGFloat = eyeLandmark.normalizedPoints[0].x
        var maxX: CGFloat = minX
        for i in 1..<eyeLandmark.pointCount {
            let x = eyeLandmark.normalizedPoints[i].x
            if x < minX { minX = x }
            if x > maxX { maxX = x }
        }
        let leftCorner = CGPoint(x: minX, y: 0)
        let rightCorner = CGPoint(x: maxX, y: 0)
        let eyeWidth = rightCorner.x - leftCorner.x
        guard eyeWidth > 0.001 else { return nil }
        let ratio = Double((pupilCenter.x - leftCorner.x) / eyeWidth)
        return ratio.clamped01()
    }
}
