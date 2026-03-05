import Foundation
import Vision
import AppKit

@MainActor
final class GazeEngine: CameraDelegate {
    private let cameraManager = CameraManager()
    private let calibrationStore = CalibrationStore()
    private var dwellTimer: DwellTimer
    private var resolver: MonitorResolver?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        self.dwellTimer = DwellTimer(dwellDuration: appState.dwellTime)
        cameraManager.delegate = self

        if let data = try? calibrationStore.load() {
            appState.calibrationData = data
            appState.isCalibrated = true
            resolver = MonitorResolver(calibration: data)
        }

        NotificationCenter.default.addObserver(
            forName: .calibrationCompleted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let data = notification.object as? CalibrationData else { return }
            Task { @MainActor in
                self?.updateCalibration(data)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .dwellTimeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let duration = notification.object as? Double else { return }
            Task { @MainActor in
                self?.updateDwellTime(duration)
            }
        }
    }

    func startTracking() {
        guard appState.isCalibrated else { return }
        do {
            try cameraManager.start()
            appState.isTracking = true
        } catch {
            print("Failed to start camera: \(error)")
        }
    }

    func stopTracking() {
        cameraManager.stop()
        appState.isTracking = false
    }

    func toggleTracking() {
        if appState.isTracking { stopTracking() } else { startTracking() }
    }

    func updateCalibration(_ data: CalibrationData) {
        do {
            try calibrationStore.save(data)
            appState.calibrationData = data
            appState.isCalibrated = true
            resolver = MonitorResolver(calibration: data)
        } catch {
            print("Failed to save calibration: \(error)")
        }
    }

    func updateDwellTime(_ duration: TimeInterval) {
        dwellTimer = DwellTimer(dwellDuration: duration)
    }

    nonisolated func cameraDidCapture(faceObservation: VNFaceObservation) {
        guard let signal = GazeEstimator.estimate(from: faceObservation) else { return }
        Task { @MainActor in
            guard appState.isTracking, let resolver else { return }
            guard let target = resolver.resolve(signal) else { return }
            if let switchTo = dwellTimer.update(
                candidateScreenID: target.screenID,
                currentScreenID: appState.currentScreenID
            ) {
                appState.currentScreenID = switchTo
                if let screen = CursorController.screen(for: CGDirectDisplayID(switchTo)) {
                    CursorController.warpToScreen(screen)
                }
            }
        }
    }

    nonisolated func cameraDidFail(error: Error) {
        print("Camera error: \(error)")
    }
}
