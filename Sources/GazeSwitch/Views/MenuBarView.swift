import SwiftUI
import AppKit
import AVFoundation

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var updaterService: UpdaterService

    @State private var hasOpenedWelcome = false

    private var cameraGranted: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    private var accessibilityGranted: Bool {
        AXIsProcessTrusted()
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

            if !cameraGranted || !accessibilityGranted {
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

            Button("Check for Updates...") {
                updaterService.checkForUpdates()
            }
            .disabled(!updaterService.canCheckForUpdates)
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
            if !appState.hasSeenWelcome && !hasOpenedWelcome {
                hasOpenedWelcome = true
                openWindow(id: "welcome")
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private var permissionWarnings: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !cameraGranted {
                permissionWarningButton(
                    label: "Camera not granted",
                    url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
                )
            }
            if !accessibilityGranted {
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
