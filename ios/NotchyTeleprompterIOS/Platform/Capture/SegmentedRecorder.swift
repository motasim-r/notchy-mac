import AVFoundation

final class SegmentedRecorder: NSObject {
    enum RecorderError: LocalizedError {
        case alreadyRecording
        case notRecording
        case missingActiveSegmentURL

        var errorDescription: String? {
            switch self {
            case .alreadyRecording:
                return "A recording segment is already in progress."
            case .notRecording:
                return "No recording segment is currently running."
            case .missingActiveSegmentURL:
                return "Recording segment URL is missing."
            }
        }
    }

    private let movieOutput: AVCaptureMovieFileOutput
    private let stateQueue = DispatchQueue(label: "notchy.segmented-recorder.state")

    private var pendingStopContinuation: CheckedContinuation<URL, Error>?
    private var activeSegmentURL: URL?
    private var segmentURLs: [URL] = []

    init(movieOutput: AVCaptureMovieFileOutput) {
        self.movieOutput = movieOutput
        super.init()
    }

    var isRecording: Bool {
        movieOutput.isRecording
    }

    func startSegment() throws {
        guard !movieOutput.isRecording else {
            throw RecorderError.alreadyRecording
        }

        let url = nextSegmentURL()
        let folderURL = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        stateQueue.sync {
            activeSegmentURL = url
        }

        movieOutput.startRecording(to: url, recordingDelegate: self)
    }

    func finishCurrentSegment() async throws -> URL {
        guard movieOutput.isRecording else {
            throw RecorderError.notRecording
        }

        return try await withCheckedThrowingContinuation { continuation in
            stateQueue.sync {
                pendingStopContinuation = continuation
            }

            movieOutput.stopRecording()
        }
    }

    func allSegments() -> [URL] {
        stateQueue.sync { segmentURLs }
    }

    func resetSegments(clearFiles: Bool) {
        let urls: [URL] = stateQueue.sync {
            let snapshot = segmentURLs
            segmentURLs.removeAll()
            activeSegmentURL = nil
            pendingStopContinuation = nil
            return snapshot
        }

        guard clearFiles else {
            return
        }

        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func nextSegmentURL() -> URL {
        let filename = "segment-\(UUID().uuidString).mov"
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("NotchyTeleprompterIOS", isDirectory: true)
            .appendingPathComponent(filename)
    }
}

extension SegmentedRecorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        _ = output
        _ = fileURL
        _ = connections
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        _ = output
        _ = connections

        let state = stateQueue.sync { () -> (CheckedContinuation<URL, Error>?, URL?) in
            let continuation = pendingStopContinuation
            pendingStopContinuation = nil

            let activeURL = activeSegmentURL
            activeSegmentURL = nil

            return (continuation, activeURL)
        }

        let continuation = state.0
        let expectedURL = state.1

        if let error {
            continuation?.resume(throwing: error)
            return
        }

        guard let expectedURL else {
            continuation?.resume(throwing: RecorderError.missingActiveSegmentURL)
            return
        }

        stateQueue.sync {
            segmentURLs.append(expectedURL)
        }

        continuation?.resume(returning: outputFileURL)
    }
}
