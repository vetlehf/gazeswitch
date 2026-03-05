import SwiftUI
import AppKit
import AVFoundation

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    let showWelcome: Bool

    @State private var cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var accessibilityPermission = AXIsProcessTrusted()

    init(showWelcome: Bool = false) {
        self.showWelcome = showWelcome
    }

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

            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            } else if !appState.isCalibrated {
                Text("Calibration required")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
            }

            if cameraPermission != .authorized || !accessibilityPermission {
                permissionWarnings
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

            Button("About GazeSwitch") {
                openWindow(id: "about")
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
            .padding(.horizontal)

            Divider()

            Button("Buy Me a Coffee") {
                if let url = URL(string: "https://buymeacoffee.com/vetfin") {
                    NSWorkspace.shared.open(url)
                }
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
        .onAppear {
            cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
            accessibilityPermission = AXIsProcessTrusted()
            if showWelcome {
                openWindow(id: "welcome")
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private var permissionWarnings: some View {
        VStack(alignment: .leading, spacing: 4) {
            if cameraPermission != .authorized {
                permissionWarningButton(
                    label: "Camera not granted",
                    url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
                )
            }
            if !accessibilityPermission {
                permissionWarningButton(
                    label: "Accessibility not granted",
                    url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                )
            }
        }
        .padding(.horizontal)
    }

    private func permissionWarningButton(label: String, url: String) -> some View {
        Button {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text(label)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }
}
