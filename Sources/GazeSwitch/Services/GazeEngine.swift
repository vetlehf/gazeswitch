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
    private var observers: [Any] = []
    private var isToggling = false

    init(appState: AppState) {
        self.appState = appState
        self.dwellTimer = DwellTimer(dwellDuration: appState.dwellTime)
        cameraManager.delegate = self

        // BUG-3 fix: init currentScreenID from actual mouse position
        if let currentScreen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }),
           let id = currentScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 {
            appState.currentScreenID = id
            GazeLog.engine.info("Initial screen ID: \(id)")
        }

        if let data = try? calibrationStore.load() {
            appState.calibrationData = data
            appState.isCalibrated = true
            resolver = MonitorResolver(calibration: data)
            GazeLog.engine.info("Loaded calibration with \(data.monitors.count) monitors")
        }

        nonisolated(unsafe) let weakSelf = { [weak self] in self }

        observers.append(NotificationCenter.default.addObserver(
            forName: .calibrationCompleted,
            object: nil,
            queue: .main
        ) { notification in
            guard let data = notification.object as? CalibrationData else { return }
            Task { @MainActor in
                weakSelf()?.updateCalibration(data)
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .dwellTimeChanged,
            object: nil,
            queue: .main
        ) { notification in
            guard let duration = notification.object as? Double else { return }
            Task { @MainActor in
                weakSelf()?.updateDwellTime(duration)
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .cameraChanged,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                weakSelf()?.handleCameraChanged()
            }
        })
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func startTracking() {
        guard appState.isCalibrated else {
            GazeLog.engine.warning("Cannot start: not calibrated")
            return
        }
        do {
            try cameraManager.start(withDeviceID: appState.selectedCameraID)
            appState.isTracking = true
            appState.errorMessage = nil
            GazeLog.engine.info("Tracking started")
        } catch {
            appState.errorMessage = "Camera failed: \(error.localizedDescription)"
            GazeLog.engine.error("Start tracking failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stopTracking() {
        cameraManager.stop()
        appState.isTracking = false
        GazeLog.engine.info("Tracking stopped")
    }

    func toggleTracking() {
        guard !isToggling else { return }
        isToggling = true
        defer { isToggling = false }
        if appState.isTracking { stopTracking() } else { startTracking() }
    }

    private func handleCameraChanged() {
        let wasTracking = appState.isTracking
        if wasTracking {
            stopTracking()
            startTracking()
            GazeLog.engine.info("Camera changed, restarted tracking")
        }
    }

    func updateCalibration(_ data: CalibrationData) {
        do {
            try calibrationStore.save(data)
            appState.calibrationData = data
            appState.isCalibrated = true
            appState.errorMessage = nil
            resolver = MonitorResolver(calibration: data)
        } catch {
            appState.errorMessage = "Failed to save calibration: \(error.localizedDescription)"
        }
    }

    func updateDwellTime(_ duration: TimeInterval) {
        dwellTimer = DwellTimer(dwellDuration: duration)
    }

    func cameraDidCapture(faceObservation: VNFaceObservation) {
        guard let signal = GazeEstimator.estimate(from: faceObservation) else {
            return
        }
        GazeLog.gaze.debug("Signal: pupil=\(signal.pupilRatio, privacy: .public) yaw=\(signal.yaw, privacy: .public)")
        guard appState.isTracking, let resolver else { return }
        guard let target = resolver.resolve(signal) else {
            GazeLog.resolver.debug("No monitor resolved for signal")
            return
        }
        if let switchTo = dwellTimer.update(
            candidateScreenID: target.screenID,
            currentScreenID: appState.currentScreenID
        ) {
            GazeLog.engine.info("Switching from screen \(self.appState.currentScreenID) to \(switchTo)")
            appState.currentScreenID = switchTo
            if let screen = CursorController.screen(for: CGDirectDisplayID(switchTo)) {
                CursorController.warpToScreen(screen)
            } else {
                GazeLog.engine.error("No NSScreen found for displayID \(switchTo)")
            }
        }
    }

    func cameraDidFail(error: Error) {
        GazeLog.camera.error("Camera error: \(error.localizedDescription, privacy: .public)")
        appState.errorMessage = "Camera error: \(error.localizedDescription)"
    }
}
