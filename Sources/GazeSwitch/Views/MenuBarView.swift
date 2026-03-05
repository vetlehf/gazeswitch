import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: appState.isTracking ? "eye.fill" : "eye")
                    .foregroundColor(appState.isTracking ? .green : .secondary)
                Text(appState.isTracking ? "Tracking" : "Paused")
                    .font(.headline)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if !appState.isCalibrated {
                Text("Calibration required")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
            }

            Divider()

            Button(appState.isTracking ? "Stop Tracking" : "Start Tracking") {
                NotificationCenter.default.post(name: .toggleTracking, object: nil)
            }
            .disabled(!appState.isCalibrated)
            .padding(.horizontal)

            Button("Calibrate...") {
                openWindow(id: "calibration")
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
            .padding(.horizontal)

            Divider()

            SettingsLink {
                Text("Settings...")
            }
            .padding(.horizontal)

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 200)
    }
}
