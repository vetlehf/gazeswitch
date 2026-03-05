import SwiftUI

@Observable
final class AppState {
    private enum Key {
        static let dwellTime = "dwellTime"
        static let launchAtLogin = "launchAtLogin"
        static let selectedCameraID = "selectedCameraID"
        static let hasSeenWelcome = "hasSeenWelcome"
    }

    var isTracking: Bool = false
    var currentScreenID: UInt32 = 0
    var isCalibrated: Bool = false
    var calibrationData: CalibrationData?
    var errorMessage: String?

    var dwellTime: Double {
        get { UserDefaults.standard.double(forKey: Key.dwellTime).nonZero ?? 0.3 }
        set { UserDefaults.standard.set(newValue, forKey: Key.dwellTime) }
    }

    var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: Key.launchAtLogin) }
        set { UserDefaults.standard.set(newValue, forKey: Key.launchAtLogin) }
    }

    var selectedCameraID: String? {
        get { UserDefaults.standard.string(forKey: Key.selectedCameraID) }
        set { UserDefaults.standard.set(newValue, forKey: Key.selectedCameraID) }
    }

    var hasSeenWelcome: Bool {
        get { UserDefaults.standard.bool(forKey: Key.hasSeenWelcome) }
        set { UserDefaults.standard.set(newValue, forKey: Key.hasSeenWelcome) }
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
