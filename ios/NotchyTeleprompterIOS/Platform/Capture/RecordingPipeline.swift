import Foundation

enum RecordingPipelineError: LocalizedError {
    case invalidState
    case noSegments

    var errorDescription: String? {
        switch self {
        case .invalidState:
            return "Recording action is not valid right now."
        case .noSegments:
            return "No recording content is available to save."
        }
    }
}

final class RecordingPipeline: RecordingPipelineProtocol {
    private enum PipelineState {
        case idle
        case recording
        case paused
    }

    private let captureManager: CaptureSessionManaging
    private let segmentedRecorder: SegmentedRecorder
    private let segmentComposer: SegmentComposer
    private let photoExporter: PhotoLibraryExporting

    private var state: PipelineState = .idle

    init(
        captureManager: CaptureSessionManaging,
        segmentedRecorder: SegmentedRecorder,
        segmentComposer: SegmentComposer = SegmentComposer(),
        photoExporter: PhotoLibraryExporting = PhotoLibraryExporter()
    ) {
        self.captureManager = captureManager
        self.segmentedRecorder = segmentedRecorder
        self.segmentComposer = segmentComposer
        self.photoExporter = photoExporter
    }

    func startRecording() async throws {
        guard state == .idle else {
            throw RecordingPipelineError.invalidState
        }

        try await captureManager.prepareSession()
        captureManager.startSession()
        captureManager.configureRecordingConnection()

        segmentedRecorder.resetSegments(clearFiles: true)
        try segmentedRecorder.startSegment()
        state = .recording
    }

    func pauseRecording() async throws {
        guard state == .recording else {
            throw RecordingPipelineError.invalidState
        }

        _ = try await segmentedRecorder.finishCurrentSegment()
        state = .paused
    }

    func resumeRecording() async throws {
        guard state == .paused else {
            throw RecordingPipelineError.invalidState
        }

        try segmentedRecorder.startSegment()
        state = .recording
    }

    func stopRecordingAndSave() async throws -> String {
        guard state == .recording || state == .paused else {
            throw RecordingPipelineError.invalidState
        }

        if state == .recording {
            _ = try await segmentedRecorder.finishCurrentSegment()
        }

        let segments = segmentedRecorder.allSegments()
        guard !segments.isEmpty else {
            state = .idle
            throw RecordingPipelineError.noSegments
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("NotchyTeleprompterIOS", isDirectory: true)
            .appendingPathComponent("final-\(UUID().uuidString).mov")

        let folderURL = outputURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        let mergedURL = try await segmentComposer.compose(segments: segments, outputURL: outputURL)
        let assetIdentifier = try await photoExporter.saveVideo(at: mergedURL)

        try? FileManager.default.removeItem(at: mergedURL)
        segmentedRecorder.resetSegments(clearFiles: true)

        state = .idle
        return assetIdentifier
    }

    func reset() async {
        if segmentedRecorder.isRecording {
            _ = try? await segmentedRecorder.finishCurrentSegment()
        }

        segmentedRecorder.resetSegments(clearFiles: true)
        state = .idle
    }
}
