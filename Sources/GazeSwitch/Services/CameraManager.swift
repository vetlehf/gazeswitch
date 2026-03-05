@preconcurrency import AVFoundation
@preconcurrency import Vision

protocol CameraDelegate: AnyObject {
    func cameraDidCapture(faceObservation: VNFaceObservation)
    func cameraDidFail(error: Error)
}

final class CameraManager: NSObject, Sendable {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.gazeswitch.camera", qos: .userInteractive)

    nonisolated(unsafe) weak var delegate: CameraDelegate?

    private let faceLandmarksRequest: VNDetectFaceLandmarksRequest

    override init() {
        var request: VNDetectFaceLandmarksRequest!
        request = VNDetectFaceLandmarksRequest { _, _ in }
        request.revision = VNDetectFaceLandmarksRequestRevision3
        self.faceLandmarksRequest = request
        super.init()
    }

    func start() throws {
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .front
        ) ?? AVCaptureDevice.default(for: .video) else {
            throw CameraError.noCameraAvailable
        }

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
    }

    func stop() {
        captureSession.stopRunning()
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

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )

        do {
            try handler.perform([faceLandmarksRequest])
            if let results = faceLandmarksRequest.results, let face = results.first {
                delegate?.cameraDidCapture(faceObservation: face)
            }
        } catch {
            delegate?.cameraDidFail(error: error)
        }
    }
}
