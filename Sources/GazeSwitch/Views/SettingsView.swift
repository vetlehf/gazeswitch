import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            GeneralTab()
                .environment(appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 400, height: 250)
        .onDisappear {
            if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}

private struct GeneralTab: View {
    @Environment(AppState.self) private var appState
    @AppStorage("dwellTime") private var dwellTime: Double = 0.3
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    var body: some View {
        Form {
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
                    NotificationCenter.default.post(
                        name: .dwellTimeChanged,
                        object: newValue
                    )
                }

                HStack {
                    Text("Sensitivity")
                    Slider(value: Binding(
                        get: { appState.sensitivity },
                        set: { appState.sensitivity = $0 }
                    ), in: 0.1...1.0, step: 0.1) {
                        Text("Sensitivity")
                    }
                    Text(sensitivityLabel)
                        .frame(width: 60)
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            launchAtLogin = newValue
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                            print("Login item error: \(error)")
                        }
                    }
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
    }

    private var sensitivityLabel: String {
        switch appState.sensitivity {
        case ..<0.4: return "Low"
        case 0.4..<0.7: return "Medium"
        default: return "High"
        }
    }
}
