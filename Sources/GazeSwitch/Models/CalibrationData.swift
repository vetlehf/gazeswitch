import Foundation

struct MonitorCalibration: Codable, Equatable, Sendable {
    let screenID: UInt32
    let gazeCenter: GazeSignal
    let screenCenter: CGPoint
}

struct CalibrationData: Codable, Equatable, Sendable {
    let monitors: [MonitorCalibration]
    let boundaries: [Double]
    let timestamp: Date

    init(monitors: [MonitorCalibration], boundaries: [Double], timestamp: Date = Date()) {
        self.monitors = monitors
        self.boundaries = boundaries
        self.timestamp = timestamp
    }
}
