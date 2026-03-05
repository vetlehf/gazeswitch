import Foundation

extension Double {
    func clamped01() -> Double { min(max(self, 0.0), 1.0) }
}

struct GazeSignal: Codable, Equatable, Sendable {
    let pupilRatio: Double
    let yaw: Double

    func combinedScore(pupilWeight: Double = 0.4, yawWeight: Double = 0.6) -> Double {
        let maxYaw = Double.pi / 2.0
        let normalizedYaw = (yaw + maxYaw) / (2.0 * maxYaw)
        return pupilWeight * pupilRatio.clamped01() + yawWeight * normalizedYaw.clamped01()
    }
}
