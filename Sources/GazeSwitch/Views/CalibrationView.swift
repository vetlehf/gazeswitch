import SwiftUI
import Vision

struct CalibrationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var samples: [(screenID: UInt32, position: CalibrationPosition, signal: GazeSignal)] = []
    @State private var isCapturing = false
    @State private var capturedSignals: [GazeSignal] = []
    @State private var cameraManager: CameraManager?
    @State private var statusMessage = "Press Start to begin calibration"
    @State private var collector: CalibrationCollector?

    private var screens: [MonitorInfo] {
        MonitorInfo.allMonitors()
    }

    private var totalSteps: Int { screens.count * CalibrationPosition.allCases.count }
    private var currentScreenIndex: Int { currentStep / CalibrationPosition.allCases.count }
    private var currentPosition: CalibrationPosition { CalibrationPosition.allCases[currentStep % CalibrationPosition.allCases.count] }

    var body: some View {
        VStack(spacing: 24) {
            Text("Calibration")
                .font(.title)
                .bold()

            if screens.count < 2 {
                Text("Connect at least 2 monitors to use GazeSwitch.")
                    .foregroundColor(.orange)
            } else if currentStep < totalSteps {
                calibrationStepView
            } else {
                completionView
            }
        }
        .padding(32)
        .frame(minWidth: 500, minHeight: 350)
        .onDisappear {
            cameraManager?.stop()
        }
        .restoreAccessoryPolicyOnDismiss()
    }

    private var calibrationStepView: some View {
        VStack(spacing: 16) {
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.headline)

            Text("Look at the **\(positionLabel)** of **\(screens[currentScreenIndex].name)** and press the button below.")
                .multilineTextAlignment(.center)

            Circle()
                .fill(isCapturing ? Color.green : Color.blue)
                .frame(width: 40, height: 40)
                .animation(.easeInOut, value: isCapturing)

            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(isCapturing ? "Capturing..." : "Capture") {
                captureCurrentGaze()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCapturing)
            .keyboardShortcut(.space, modifiers: [])
        }
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Calibration Complete!")
                .font(.headline)

            Text("\(screens.count) monitors calibrated (5 points each).")
                .foregroundColor(.secondary)

            Button("Done") {
                saveCalibration()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var positionLabel: String { currentPosition.label }

    private func captureCurrentGaze() {
        isCapturing = true
        statusMessage = "Hold your gaze for 2 seconds..."
        capturedSignals = []

        if cameraManager == nil {
            let manager = CameraManager()
            let col = CalibrationCollector(onSignal: { signal in
                capturedSignals.append(signal)
            })
            collector = col
            manager.delegate = col
            cameraManager = manager
            do {
                try manager.start(withDeviceID: appState.selectedCameraID)
            } catch {
                statusMessage = "Camera error: \(error.localizedDescription)"
                isCapturing = false
                return
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            finishCapture()
        }
    }

    private func finishCapture() {
        guard !capturedSignals.isEmpty else {
            statusMessage = "No face detected. Try again."
            isCapturing = false
            return
        }

        let avgPupil = capturedSignals.map(\.pupilRatio).reduce(0, +) / Double(capturedSignals.count)
        let avgYaw = capturedSignals.map(\.yaw).reduce(0, +) / Double(capturedSignals.count)
        let avgSignal = GazeSignal(pupilRatio: avgPupil, yaw: avgYaw)

        let screen = screens[currentScreenIndex]
        samples.append((screenID: screen.displayID, position: currentPosition, signal: avgSignal))

        capturedSignals = []
        currentStep += 1
        isCapturing = false
        statusMessage = currentStep < totalSteps
            ? "Ready for next position"
            : "All positions captured!"
    }

    private func saveCalibration() {
        let grouped = Dictionary(grouping: samples, by: { $0.screenID })
        let monitors = grouped.map { (screenID, screenSamples) -> MonitorCalibration in
            let screen = screens.first { $0.displayID == screenID }
            let centerSample = screenSamples.first { $0.position == .center }
            let gazeCenter = centerSample?.signal ?? screenSamples[0].signal
            let gazePoints = screenSamples.map {
                CalibrationPoint(position: $0.position, signal: $0.signal)
            }
            return MonitorCalibration(
                screenID: screenID,
                gazeCenter: gazeCenter,
                screenCenter: screen?.center ?? .zero,
                gazePoints: gazePoints
            )
        }

        let scored = monitors.map { ($0, $0.gazeCenter.combinedScore()) }
        let sorted = scored.sorted { $0.1 < $1.1 }
        var boundaries: [Double] = []
        for i in 0..<(sorted.count - 1) {
            boundaries.append((sorted[i].1 + sorted[i + 1].1) / 2.0)
        }

        let data = CalibrationData(monitors: monitors, boundaries: boundaries)
        NotificationCenter.default.post(name: .calibrationCompleted, object: data)

        cameraManager?.stop()
        cameraManager = nil
        collector = nil
    }
}

@MainActor
final class CalibrationCollector: CameraDelegate {
    private let onSignal: (GazeSignal) -> Void

    init(onSignal: @escaping (GazeSignal) -> Void) {
        self.onSignal = onSignal
    }

    func cameraDidCapture(faceObservation: VNFaceObservation) {
        if let signal = GazeEstimator.estimate(from: faceObservation) {
            onSignal(signal)
        }
    }

    func cameraDidFail(error: Error) {
        GazeLog.camera.error("Calibration camera error: \(error.localizedDescription, privacy: .public)")
    }
}
