import Foundation

struct MonitorCalibration: Codable, Equatable, Sendable {
    let screenID: UInt32
    let gazeCenter: GazeSignal
    let screenCenter: CGPoint
    let gazePoints: [CalibrationPoint]
    let scoreRange: ClosedRange<Double>?

    init(screenID: UInt32, gazeCenter: GazeSignal, screenCenter: CGPoint, gazePoints: [CalibrationPoint] = []) {
        self.screenID = screenID
        self.gazeCenter = gazeCenter
        self.screenCenter = screenCenter
        self.gazePoints = gazePoints
        self.scoreRange = Self.computeScoreRange(gazePoints: gazePoints, gazeCenter: gazeCenter)
    }

    private static func computeScoreRange(gazePoints: [CalibrationPoint], gazeCenter: GazeSignal) -> ClosedRange<Double>? {
        let scores = gazePoints.isEmpty
            ? [gazeCenter.combinedScore()]
            : gazePoints.map { $0.signal.combinedScore() }
        guard let lo = scores.min(), let hi = scores.max(), lo < hi else {
            return nil
        }
        return lo...hi
    }

    private enum CodingKeys: String, CodingKey {
        case screenID, gazeCenter, screenCenter, gazePoints
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(screenID, forKey: .screenID)
        try container.encode(gazeCenter, forKey: .gazeCenter)
        try container.encode(screenCenter, forKey: .screenCenter)
        try container.encode(gazePoints, forKey: .gazePoints)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        screenID = try container.decode(UInt32.self, forKey: .screenID)
        gazeCenter = try container.decode(GazeSignal.self, forKey: .gazeCenter)
        screenCenter = try container.decode(CGPoint.self, forKey: .screenCenter)
        gazePoints = try container.decodeIfPresent([CalibrationPoint].self, forKey: .gazePoints) ?? []
        scoreRange = Self.computeScoreRange(gazePoints: gazePoints, gazeCenter: gazeCenter)
    }
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
