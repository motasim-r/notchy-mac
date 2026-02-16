import AVFoundation

enum CapturePermissionState {
    case authorized
    case denied
    case restricted
    case notDetermined
}

struct CapturePermissionSnapshot {
    let camera: CapturePermissionState
    let microphone: CapturePermissionState
}

protocol CaptureSessionManaging: AnyObject {
    var session: AVCaptureSession { get }
    var movieOutput: AVCaptureMovieFileOutput { get }

    func requestPermissions() async -> CapturePermissionSnapshot
    func prepareSession() async throws
    func startSession()
    func stopSession()
    func configurePreviewConnection(_ connection: AVCaptureConnection?)
    func configureRecordingConnection()
}
