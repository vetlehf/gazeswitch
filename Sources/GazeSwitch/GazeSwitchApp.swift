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

        Settings {
            SettingsView()
                .environment(appState)
        }
    }

    private func setupEngine() {
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
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.command, .shift] && event.keyCode == 14 {
                DispatchQueue.main.async {
                    gazeEngine?.toggleTracking()
                }
            }
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.command, .shift] && event.keyCode == 14 {
                DispatchQueue.main.async {
                    gazeEngine?.toggleTracking()
                }
                return nil
            }
            return event
        }
    }

    private func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                print("Camera permission denied")
            }
        }
        CursorController.requestAccessibilityPermission()
    }
}
