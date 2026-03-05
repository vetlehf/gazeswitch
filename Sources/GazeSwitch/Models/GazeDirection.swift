import Foundation

struct GazeSignal: Codable, Equatable, Sendable {
    let pupilRatio: Double
    let yaw: Double

    func combinedScore(pupilWeight: Double = 0.4, yawWeight: Double = 0.6) -> Double {
        let maxYaw = Double.pi / 2.0
        let normalizedYaw = (yaw + maxYaw) / (2.0 * maxYaw)
        let clampedYaw = min(max(normalizedYaw, 0.0), 1.0)
        let clampedPupil = min(max(pupilRatio, 0.0), 1.0)
        return pupilWeight * clampedPupil + yawWeight * clampedYaw
    }
}
