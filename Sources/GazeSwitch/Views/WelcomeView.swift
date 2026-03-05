import SwiftUI
import AVFoundation

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    @State private var currentStep = 0
    @State private var cameraGranted = false
    @State private var accessibilityGranted = false

    var body: some View {
        VStack(spacing: 24) {
            switch currentStep {
            case 0:
                welcomeStep
            case 1:
                permissionsStep
            default:
                getStartedStep
            }
        }
        .padding(32)
        .frame(width: 400, height: 350)
        .onAppear {
            refreshPermissions()
        }
        .onDisappear {
            appState.hasSeenWelcome = true
        }
        .restoreAccessoryPolicyOnDismiss()
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Welcome to GazeSwitch")
                .font(.title)
                .bold()

            Text("GazeSwitch tracks your eye gaze via webcam and automatically moves your cursor to the monitor you're looking at.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()

            Button("Continue") {
                currentStep = 1
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var permissionsStep: some View {
        VStack(spacing: 16) {
            Text("Permissions")
                .font(.title2)
                .bold()

            Text("GazeSwitch needs two permissions to work.")
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                permissionRow(
                    title: "Camera",
                    description: "Track your eyes via webcam",
                    systemImage: "camera.fill",
                    granted: cameraGranted
                ) {
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        Task { @MainActor in
                            cameraGranted = granted
                        }
                    }
                }

                permissionRow(
                    title: "Accessibility",
                    description: "Move cursor between monitors",
                    systemImage: "accessibility",
                    granted: accessibilityGranted
                ) {
                    CursorController.requestAccessibilityPermission()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1))
                        refreshPermissions()
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

            Spacer()

            Button("Continue") {
                currentStep = 2
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var getStartedStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("You're all set!")
                .font(.title2)
                .bold()

            Text("Calibrate your monitors to start using GazeSwitch. You can always recalibrate later from the menu bar.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 12) {
                Button("Skip") {
                    dismiss()
                }

                Button("Calibrate Now") {
                    dismiss()
                    openWindow(id: "calibration")
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func permissionRow(
        title: String,
        description: String,
        systemImage: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Grant") { action() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private func refreshPermissions() {
        cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        accessibilityGranted = AXIsProcessTrusted()
    }
}
