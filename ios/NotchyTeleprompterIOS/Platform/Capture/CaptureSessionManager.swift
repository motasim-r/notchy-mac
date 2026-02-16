import AVFoundation
import UIKit

final class CaptureSessionManager: CaptureSessionManaging {
    private let sessionQueue = DispatchQueue(label: "notchy.capture.session")
    private(set) var isPrepared = false

    let session = AVCaptureSession()
    let movieOutput = AVCaptureMovieFileOutput()

    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?

    func requestPermissions() async -> CapturePermissionSnapshot {
        async let camera = requestCameraPermission()
        async let microphone = requestMicrophonePermission()

        return await CapturePermissionSnapshot(camera: camera, microphone: microphone)
    }

    func prepareSession() async throws {
        if isPrepared {
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    try self.configureSessionIfNeeded()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func startSession() {
        sessionQueue.async {
            guard !self.session.isRunning else {
                return
            }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else {
                return
            }
            self.session.stopRunning()
        }
    }

    func configurePreviewConnection(_ connection: AVCaptureConnection?) {
        guard let connection else {
            return
        }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }

    func configureRecordingConnection() {
        guard let connection = movieOutput.connection(with: .video) else {
            return
        }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
    }

    private func configureSessionIfNeeded() throws {
        guard !isPrepared else {
            return
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .hd1920x1080

        if let existingInput = videoInput {
            session.removeInput(existingInput)
        }

        if let existingInput = audioInput {
            session.removeInput(existingInput)
        }

        if session.outputs.contains(movieOutput) {
            session.removeOutput(movieOutput)
        }

        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CaptureSessionError.frontCameraUnavailable
        }

        let newVideoInput = try AVCaptureDeviceInput(device: cameraDevice)
        guard session.canAddInput(newVideoInput) else {
            throw CaptureSessionError.cannotAddVideoInput
        }
        session.addInput(newVideoInput)
        videoInput = newVideoInput

        guard let micDevice = AVCaptureDevice.default(for: .audio) else {
            throw CaptureSessionError.microphoneUnavailable
        }

        let newAudioInput = try AVCaptureDeviceInput(device: micDevice)
        guard session.canAddInput(newAudioInput) else {
            throw CaptureSessionError.cannotAddAudioInput
        }
        session.addInput(newAudioInput)
        audioInput = newAudioInput

        guard session.canAddOutput(movieOutput) else {
            throw CaptureSessionError.cannotAddMovieOutput
        }
        session.addOutput(movieOutput)

        configureRecordingConnection()
        isPrepared = true
    }

    private func requestCameraPermission() async -> CapturePermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        @unknown default:
            return .denied
        }
    }

    private func requestMicrophonePermission() async -> CapturePermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            return granted ? .authorized : .denied
        @unknown default:
            return .denied
        }
    }
}

enum CaptureSessionError: LocalizedError {
    case frontCameraUnavailable
    case microphoneUnavailable
    case cannotAddVideoInput
    case cannotAddAudioInput
    case cannotAddMovieOutput

    var errorDescription: String? {
        switch self {
        case .frontCameraUnavailable:
            return "Front camera is unavailable on this device."
        case .microphoneUnavailable:
            return "Microphone is unavailable on this device."
        case .cannotAddVideoInput:
            return "Unable to configure the front camera input."
        case .cannotAddAudioInput:
            return "Unable to configure the microphone input."
        case .cannotAddMovieOutput:
            return "Unable to configure movie recording output."
        }
    }
}
