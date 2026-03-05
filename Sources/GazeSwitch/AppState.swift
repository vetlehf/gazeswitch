import SwiftUI

@Observable
final class AppState {
    var isTracking: Bool = false
    var currentScreenID: UInt32 = 0
    var isCalibrated: Bool = false
    var calibrationData: CalibrationData?

    @ObservationIgnored
    @AppStorage("dwellTime") var dwellTime: Double = 0.3

    @ObservationIgnored
    @AppStorage("sensitivity") var sensitivity: Double = 0.5

    @ObservationIgnored
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
}
