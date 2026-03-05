import AVFoundation
import Vision

@MainActor
protocol CameraDelegate: AnyObject {
    func cameraDidCapture(faceObservation: VNFaceObservation)
    func cameraDidFail(error: Error)
}

final class CameraManager: NSObject, @unchecked Sendable {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.gazeswitch.camera", qos: .userInteractive)

    nonisolated(unsafe) weak var delegate: CameraDelegate?
    private var isFrontFacing: Bool = true

    private let faceLandmarksRequest: VNDetectFaceLandmarksRequest

    override init() {
        var request: VNDetectFaceLandmarksRequest!
        request = VNDetectFaceLandmarksRequest { _, _ in }
        request.revision = VNDetectFaceLandmarksRequestRevision3
        self.faceLandmarksRequest = request
        super.init()
    }

    static func availableCameras() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        ).devices
    }

    private func clearSession() {
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
    }

    func start(withDeviceID deviceID: String? = nil) throws {
        clearSession()

        let camera: AVCaptureDevice
        if let deviceID, let device = AVCaptureDevice(uniqueID: deviceID) {
            camera = device
        } else {
            guard let defaultCamera = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .front
            ) ?? AVCaptureDevice.default(for: .video) else {
                throw CameraError.noCameraAvailable
            }
            camera = defaultCamera
        }

        isFrontFacing = camera.position == .front
        GazeLog.camera.info("Starting camera: \(camera.localizedName, privacy: .public) (front=\(self.isFrontFacing))")

        let input = try AVCaptureDeviceInput(device: camera)
        guard captureSession.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        captureSession.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddOutput
        }
        captureSession.addOutput(videoOutput)
        captureSession.startRunning()
        GazeLog.camera.info("Camera session running")
    }

    func stop() {
        captureSession.stopRunning()
        clearSession()
        GazeLog.camera.info("Camera session stopped")
    }

    enum CameraError: Error, LocalizedError {
        case noCameraAvailable
        case cannotAddInput
        case cannotAddOutput

        var errorDescription: String? {
            switch self {
            case .noCameraAvailable: return "No camera found"
            case .cannotAddInput: return "Cannot add camera input"
            case .cannotAddOutput: return "Cannot add video output"
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let orientation: CGImagePropertyOrientation = isFrontFacing ? .leftMirrored : .up
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([faceLandmarksRequest])
            if let results = faceLandmarksRequest.results, let face = results.first {
                GazeLog.camera.debug("Face detected: yaw=\(face.yaw?.doubleValue ?? 0, privacy: .public)")
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.cameraDidCapture(faceObservation: face)
                }
            } else {
                GazeLog.camera.debug("No face in frame")
            }
        } catch {
            GazeLog.camera.error("Vision error: \(error.localizedDescription, privacy: .public)")
            let capturedError = error
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.cameraDidFail(error: capturedError)
            }
        }
    }
}
