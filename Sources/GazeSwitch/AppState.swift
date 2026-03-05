import SwiftUI

@Observable
final class AppState {
    var isTracking: Bool = false
    var currentScreenID: UInt32 = 0
    var isCalibrated: Bool = false
    var calibrationData: CalibrationData?
    var errorMessage: String?

    var dwellTime: Double {
        get { UserDefaults.standard.double(forKey: "dwellTime").nonZero ?? 0.3 }
        set { UserDefaults.standard.set(newValue, forKey: "dwellTime") }
    }

    var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "launchAtLogin") }
        set { UserDefaults.standard.set(newValue, forKey: "launchAtLogin") }
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
