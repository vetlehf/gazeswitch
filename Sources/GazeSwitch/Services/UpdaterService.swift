import Foundation
import Sparkle

@MainActor
final class UpdaterService: ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    @Published var canCheckForUpdates: Bool = false

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func startUpdater() {
        do {
            try updaterController.updater.start()
        } catch {
            GazeLog.engine.error("Sparkle updater failed to start: \(error.localizedDescription, privacy: .public)")
        }

        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }
}
