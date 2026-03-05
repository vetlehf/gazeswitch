import Foundation

struct MonitorResolver: Sendable {
    private let calibration: CalibrationData

    init(calibration: CalibrationData) {
        self.calibration = calibration
    }

    func resolve(_ signal: GazeSignal) -> MonitorCalibration? {
        guard !calibration.monitors.isEmpty else { return nil }

        let score = signal.combinedScore()

        let scored = calibration.monitors.map { monitor in
            let monitorScore = monitor.gazeCenter.combinedScore()
            let distance = abs(score - monitorScore)
            return (monitor: monitor, distance: distance)
        }

        return scored.min(by: { $0.distance < $1.distance })?.monitor
    }
}
