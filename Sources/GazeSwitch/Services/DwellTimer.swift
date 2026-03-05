import Foundation

struct DwellTimer: Sendable {
    let dwellDuration: TimeInterval
    private var candidateScreenID: UInt32?
    private var candidateStartTime: Date?

    init(dwellDuration: TimeInterval = 0.3) {
        self.dwellDuration = dwellDuration
    }

    mutating func update(
        candidateScreenID: UInt32,
        currentScreenID: UInt32,
        at time: Date = Date()
    ) -> UInt32? {
        guard candidateScreenID != currentScreenID else {
            reset()
            return nil
        }
        if candidateScreenID != self.candidateScreenID {
            self.candidateScreenID = candidateScreenID
            self.candidateStartTime = time
            return nil
        }
        guard let startTime = candidateStartTime else {
            self.candidateStartTime = time
            return nil
        }
        if time.timeIntervalSince(startTime) >= dwellDuration {
            reset()
            return candidateScreenID
        }
        return nil
    }

    mutating func reset() {
        candidateScreenID = nil
        candidateStartTime = nil
    }
}
