import SwiftUI
import Vision

struct CalibrationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var samples: [(screenID: UInt32, signal: GazeSignal)] = []
    @State private var isCapturing = false
    @State private var capturedSignals: [GazeSignal] = []
    @State private var cameraManager: CameraManager?
    @State private var statusMessage = "Press Start to begin calibration"
    @State private var collector: CalibrationCollector?

    private var screens: [MonitorInfo] {
        MonitorInfo.allMonitors()
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Calibration")
                .font(.title)
                .bold()

            if screens.count < 2 {
                Text("Connect at least 2 monitors to use GazeSwitch.")
                    .foregroundColor(.orange)
            } else if currentStep < screens.count {
                calibrationStepView
            } else {
                completionView
            }
        }
        .padding(32)
        .frame(minWidth: 500, minHeight: 350)
        .onDisappear {
            cameraManager?.stop()
            if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    private var calibrationStepView: some View {
        VStack(spacing: 16) {
            Text("Step \(currentStep + 1) of \(screens.count)")
                .font(.headline)

            Text("Look at the center of **\(screens[currentStep].name)** and press the button below.")
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

            Text("\(screens.count) monitors calibrated.")
                .foregroundColor(.secondary)

            Button("Done") {
                saveCalibration()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func captureCurrentGaze() {
        isCapturing = true
        statusMessage = "Hold your gaze for 2 seconds..."
        capturedSignals = []

        if cameraManager == nil {
            let manager = CameraManager()
            let col = CalibrationCollector(onSignal: { signal in
                Task { @MainActor in
                    capturedSignals.append(signal)
                }
            })
            collector = col
            manager.delegate = col
            cameraManager = manager
            do {
                try manager.start()
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

        let screen = screens[currentStep]
        samples.append((screenID: screen.displayID, signal: avgSignal))

        capturedSignals = []
        currentStep += 1
        isCapturing = false
        statusMessage = currentStep < screens.count
            ? "Ready for next monitor"
            : "All monitors captured!"
    }

    private func saveCalibration() {
        let monitors = samples.map { sample in
            let screen = screens.first { $0.displayID == sample.screenID }
            return MonitorCalibration(
                screenID: sample.screenID,
                gazeCenter: sample.signal,
                screenCenter: screen?.center ?? .zero
            )
        }

        let sorted = monitors.sorted { $0.gazeCenter.combinedScore() < $1.gazeCenter.combinedScore() }
        var boundaries: [Double] = []
        for i in 0..<(sorted.count - 1) {
            let mid = (sorted[i].gazeCenter.combinedScore() + sorted[i + 1].gazeCenter.combinedScore()) / 2.0
            boundaries.append(mid)
        }

        let data = CalibrationData(monitors: monitors, boundaries: boundaries)
        NotificationCenter.default.post(name: .calibrationCompleted, object: data)

        cameraManager?.stop()
        cameraManager = nil
        collector = nil
    }
}

final class CalibrationCollector: CameraDelegate {
    private let onSignal: @Sendable (GazeSignal) -> Void

    init(onSignal: @escaping @Sendable (GazeSignal) -> Void) {
        self.onSignal = onSignal
    }

    func cameraDidCapture(faceObservation: VNFaceObservation) {
        if let signal = GazeEstimator.estimate(from: faceObservation) {
            onSignal(signal)
        }
    }

    func cameraDidFail(error: Error) {
        print("Calibration camera error: \(error)")
    }
}
