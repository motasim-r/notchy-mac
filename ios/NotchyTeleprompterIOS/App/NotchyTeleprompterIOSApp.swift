import SwiftUI

@main
struct NotchyTeleprompterIOSApp: App {
    @StateObject private var controller: AppStateControllerIOS

    init() {
        let stateStore = FileStateStoreIOS()
        let captureManager = CaptureSessionManager()
        let segmentedRecorder = SegmentedRecorder(movieOutput: captureManager.movieOutput)
        let recordingPipeline = RecordingPipeline(
            captureManager: captureManager,
            segmentedRecorder: segmentedRecorder
        )

        _controller = StateObject(
            wrappedValue: AppStateControllerIOS(
                stateStore: stateStore,
                captureManager: captureManager,
                recordingPipeline: recordingPipeline
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootCaptureView(controller: controller)
                .preferredColorScheme(.dark)
        }
    }
}
