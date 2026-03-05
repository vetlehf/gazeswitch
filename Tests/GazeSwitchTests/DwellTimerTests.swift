import XCTest
@testable import GazeSwitch

final class DwellTimerTests: XCTestCase {
    func testNoChangeBeforeDwellTime() {
        var timer = DwellTimer(dwellDuration: 0.3)
        let now = ContinuousClock.Instant.now
        let result1 = timer.update(candidateScreenID: 2, currentScreenID: 1, at: now)
        XCTAssertNil(result1, "Should not switch immediately")
    }

    func testSwitchesAfterDwellTime() {
        var timer = DwellTimer(dwellDuration: 0.3)
        let now = ContinuousClock.Instant.now
        _ = timer.update(candidateScreenID: 2, currentScreenID: 1, at: now)
        let later = now + .milliseconds(350)
        let result = timer.update(candidateScreenID: 2, currentScreenID: 1, at: later)
        XCTAssertEqual(result, 2, "Should switch after dwell time elapsed")
    }

    func testResetsWhenCandidateChanges() {
        var timer = DwellTimer(dwellDuration: 0.3)
        let now = ContinuousClock.Instant.now
        _ = timer.update(candidateScreenID: 2, currentScreenID: 1, at: now)
        let later1 = now + .milliseconds(200)
        _ = timer.update(candidateScreenID: 3, currentScreenID: 1, at: later1)
        let later2 = now + .milliseconds(400)
        let result = timer.update(candidateScreenID: 3, currentScreenID: 1, at: later2)
        XCTAssertNil(result, "Should not switch — timer was reset")
    }

    func testNoSwitchWhenAlreadyOnTargetScreen() {
        var timer = DwellTimer(dwellDuration: 0.3)
        let now = ContinuousClock.Instant.now
        let result = timer.update(candidateScreenID: 1, currentScreenID: 1, at: now)
        XCTAssertNil(result, "Should not switch to the screen we're already on")
    }

    func testCooldownPreventsRapidSwitch() {
        var timer = DwellTimer(dwellDuration: 0.1, switchCooldown: 0.5)
        let t0 = ContinuousClock.Instant.now

        // First switch succeeds
        _ = timer.update(candidateScreenID: 2, currentScreenID: 1, at: t0)
        let switched = timer.update(candidateScreenID: 2, currentScreenID: 1, at: t0 + .milliseconds(150))
        XCTAssertEqual(switched, 2)

        // Try switching again within cooldown - should be blocked
        _ = timer.update(candidateScreenID: 3, currentScreenID: 2, at: t0 + .milliseconds(200))
        let blocked = timer.update(candidateScreenID: 3, currentScreenID: 2, at: t0 + .milliseconds(400))
        XCTAssertNil(blocked, "Should be blocked by cooldown")
    }

    func testSwitchAllowedAfterCooldown() {
        var timer = DwellTimer(dwellDuration: 0.1, switchCooldown: 0.5)
        let t0 = ContinuousClock.Instant.now

        // First switch
        _ = timer.update(candidateScreenID: 2, currentScreenID: 1, at: t0)
        let switched = timer.update(candidateScreenID: 2, currentScreenID: 1, at: t0 + .milliseconds(150))
        XCTAssertEqual(switched, 2)

        // After cooldown expires (700ms > 500ms), should work
        _ = timer.update(candidateScreenID: 3, currentScreenID: 2, at: t0 + .milliseconds(700))
        let allowed = timer.update(candidateScreenID: 3, currentScreenID: 2, at: t0 + .milliseconds(900))
        XCTAssertEqual(allowed, 3, "Should be allowed after cooldown expires")
    }
}
