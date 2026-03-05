import SwiftUI

@main
struct GazeSwitchApp: App {
    var body: some Scene {
        MenuBarExtra("GazeSwitch", systemImage: "eye") {
            Text("GazeSwitch")
                .padding()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
