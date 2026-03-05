import XCTest
@testable import GazeSwitch

final class DwellTimerTests: XCTestCase {
    func testNoChangeBeforeDwellTime() {
        var timer = DwellTimer(dwellDuration: 0.3)
        let now = Date()
        let result1 = timer.update(candidateScreenID: 2, currentScreenID: 1, at: now)
        XCTAssertNil(result1, "Should not switch immediately")
    }

    func testSwitchesAfterDwellTime() {
        var timer = DwellTimer(dwellDuration: 0.3)
        let now = Date()
        _ = timer.update(candidateScreenID: 2, currentScreenID: 1, at: now)
        let later = now.addingTimeInterval(0.35)
        let result = timer.update(candidateScreenID: 2, currentScreenID: 1, at: later)
        XCTAssertEqual(result, 2, "Should switch after dwell time elapsed")
    }

    func testResetsWhenCandidateChanges() {
        var timer = DwellTimer(dwellDuration: 0.3)
        let now = Date()
        _ = timer.update(candidateScreenID: 2, currentScreenID: 1, at: now)
        let later1 = now.addingTimeInterval(0.2)
        _ = timer.update(candidateScreenID: 3, currentScreenID: 1, at: later1)
        let later2 = now.addingTimeInterval(0.4)
        let result = timer.update(candidateScreenID: 3, currentScreenID: 1, at: later2)
        XCTAssertNil(result, "Should not switch — timer was reset")
    }

    func testNoSwitchWhenAlreadyOnTargetScreen() {
        var timer = DwellTimer(dwellDuration: 0.3)
        let now = Date()
        let result = timer.update(candidateScreenID: 1, currentScreenID: 1, at: now)
        XCTAssertNil(result, "Should not switch to the screen we're already on")
    }
}
