import SwiftUI
import ServiceManagement
import AVFoundation

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject var updaterService: UpdaterService

    var body: some View {
        TabView {
            GeneralTab(updaterService: updaterService)
                .environment(appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 400, height: 300)
        .onDisappear {
            if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}

private struct GeneralTab: View {
    @Environment(AppState.self) private var appState
    @ObservedObject var updaterService: UpdaterService
    @State private var dwellTime: Double = 0.3
    @State private var launchAtLogin: Bool = false
    @State private var cameras: [AVCaptureDevice] = []
    @State private var selectedCameraID: String = ""

    var body: some View {
        Form {
            Section("Camera") {
                Picker("Camera", selection: $selectedCameraID) {
                    Text("Default").tag("")
                    ForEach(cameras, id: \.uniqueID) { camera in
                        Text(camera.localizedName).tag(camera.uniqueID)
                    }
                }
                .onChange(of: selectedCameraID) { _, newValue in
                    appState.selectedCameraID = newValue.isEmpty ? nil : newValue
                    NotificationCenter.default.post(name: .cameraChanged, object: nil)
                }
            }

            Section("Tracking") {
                HStack {
                    Text("Dwell time")
                    Slider(value: $dwellTime, in: 0.1...1.0, step: 0.05) {
                        Text("Dwell time")
                    }
                    Text("\(Int(dwellTime * 1000))ms")
                        .monospacedDigit()
                        .frame(width: 50)
                }
                .onChange(of: dwellTime) { _, newValue in
                    appState.dwellTime = newValue
                    NotificationCenter.default.post(
                        name: .dwellTimeChanged,
                        object: newValue
                    )
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            appState.launchAtLogin = newValue
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                            GazeLog.engine.error("Login item error: \(error.localizedDescription, privacy: .public)")
                        }
                    }
            }

            Section("Updates") {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updaterService.automaticallyChecksForUpdates },
                    set: { updaterService.automaticallyChecksForUpdates = $0 }
                ))
            }

            Section("Shortcut") {
                HStack {
                    Text("Toggle tracking")
                    Spacer()
                    Text("Cmd+Shift+E")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            cameras = CameraManager.availableCameras()
            selectedCameraID = appState.selectedCameraID ?? ""
            dwellTime = appState.dwellTime
            launchAtLogin = appState.launchAtLogin
        }
    }
}
