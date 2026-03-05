import Foundation

struct MonitorResolver: Sendable {
    private let calibration: CalibrationData

    init(calibration: CalibrationData) {
        self.calibration = calibration
    }

    func resolve(_ signal: GazeSignal) -> MonitorCalibration? {
        guard !calibration.monitors.isEmpty else {
            GazeLog.resolver.debug("No calibrated monitors")
            return nil
        }

        let score = signal.combinedScore()

        // Try range-based resolution first
        let rangeMatches = calibration.monitors.filter { monitor in
            guard let range = monitor.scoreRange else { return false }
            return range.contains(score)
        }

        if rangeMatches.count == 1 {
            GazeLog.resolver.debug("Score=\(score, privacy: .public) -> screen \(rangeMatches[0].screenID) (range match)")
            return rangeMatches[0]
        }

        // Fall back to nearest center (handles: no ranges, overlapping ranges, out-of-range)
        let pool = rangeMatches.isEmpty ? calibration.monitors : rangeMatches
        return nearestByCenter(score: score, monitors: pool)
    }

    private func nearestByCenter(score: Double, monitors: [MonitorCalibration]) -> MonitorCalibration? {
        let result = monitors.min(by: {
            abs(score - $0.gazeCenter.combinedScore()) < abs(score - $1.gazeCenter.combinedScore())
        })
        if let result {
            GazeLog.resolver.debug("Score=\(score, privacy: .public) -> screen \(result.screenID) (nearest center)")
        }
        return result
    }
}
