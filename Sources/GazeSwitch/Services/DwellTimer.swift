import Foundation

struct DwellTimer: Sendable {
    private let dwellDuration: Duration
    private let switchCooldown: Duration
    private var candidateScreenID: UInt32?
    private var candidateStart: ContinuousClock.Instant?
    private var lastSwitchTime: ContinuousClock.Instant?

    init(dwellDuration: TimeInterval = 0.3, switchCooldown: TimeInterval = 0.5) {
        self.dwellDuration = .milliseconds(Int(dwellDuration * 1000))
        self.switchCooldown = .milliseconds(Int(switchCooldown * 1000))
    }

    mutating func update(
        candidateScreenID: UInt32,
        currentScreenID: UInt32,
        at time: ContinuousClock.Instant = .now
    ) -> UInt32? {
        if let lastSwitch = lastSwitchTime, time - lastSwitch < switchCooldown {
            return nil
        }

        guard candidateScreenID != currentScreenID else {
            reset()
            return nil
        }
        if candidateScreenID != self.candidateScreenID {
            self.candidateScreenID = candidateScreenID
            self.candidateStart = time
            return nil
        }
        guard let start = candidateStart else {
            self.candidateStart = time
            return nil
        }
        if time - start >= dwellDuration {
            reset()
            lastSwitchTime = time
            return candidateScreenID
        }
        return nil
    }

    mutating func reset() {
        candidateScreenID = nil
        candidateStart = nil
    }
}
