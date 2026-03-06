import SwiftUI
import AVFoundation

@main
struct GazeSwitchApp: App {
    @State private var appState = AppState()
    @State private var gazeEngine: GazeEngine?

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
                .onAppear {
                    setupEngine()
                    setupNotifications()
                    setupGlobalHotkey()
                    checkPermissions()
                }
        } label: {
            Image(systemName: appState.isTracking ? "eye.fill" : "eye")
        }
        .menuBarExtraStyle(.window)

        Window("Calibrate GazeSwitch", id: "calibration") {
            CalibrationView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Welcome to GazeSwitch", id: "welcome") {
            WelcomeView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("About GazeSwitch", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }

    @MainActor private func setupEngine() {
        if gazeEngine == nil {
            gazeEngine = GazeEngine(appState: appState)
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .toggleTracking,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                gazeEngine?.toggleTracking()
            }
        }
    }

    private func setupGlobalHotkey() {
        let isHotkey: (NSEvent) -> Bool = { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            return flags == [.command, .shift]
                && event.charactersIgnoringModifiers?.lowercased() == "e"
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard isHotkey(event) else { return }
            Task { @MainActor in
                gazeEngine?.toggleTracking()
            }
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isHotkey(event) else { return event }
            Task { @MainActor in
                gazeEngine?.toggleTracking()
            }
            return nil
        }
    }

    private func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                Task { @MainActor in
                    appState.errorMessage = "Camera access denied. Enable in System Settings > Privacy > Camera."
                }
            }
        }
        if !CursorController.requestAccessibilityPermission() {
            GazeLog.engine.warning("Accessibility permission not yet granted")
        }
    }
}
