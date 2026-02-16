import AVFoundation

enum SegmentComposerError: LocalizedError {
    case noSegments
    case noVideoTrack
    case cannotCreateExportSession
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .noSegments:
            return "No recording segments were captured."
        case .noVideoTrack:
            return "Unable to find video track in one or more recording segments."
        case .cannotCreateExportSession:
            return "Unable to build export session for final recording."
        case .exportFailed:
            return "Final recording export failed."
        }
    }
}

struct SegmentComposer {
    func compose(segments: [URL], outputURL: URL) async throws -> URL {
        guard !segments.isEmpty else {
            throw SegmentComposerError.noSegments
        }

        let composition = AVMutableComposition()
        guard let compositionVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw SegmentComposerError.noVideoTrack
        }

        let compositionAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        var cursor = CMTime.zero

        for segmentURL in segments {
            let asset = AVURLAsset(url: segmentURL)
            let duration = try await asset.load(.duration)
            let videoTracks = try await asset.loadTracks(withMediaType: .video)

            guard let sourceVideo = videoTracks.first else {
                throw SegmentComposerError.noVideoTrack
            }

            try compositionVideo.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: sourceVideo,
                at: cursor
            )

            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            if let sourceAudio = audioTracks.first, let compositionAudio {
                try compositionAudio.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: sourceAudio,
                    at: cursor
                )
            }

            cursor = CMTimeAdd(cursor, duration)
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw SegmentComposerError.cannotCreateExportSession
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true

        try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                if let error = exportSession.error {
                    continuation.resume(throwing: error)
                    return
                }

                guard exportSession.status == .completed else {
                    continuation.resume(throwing: SegmentComposerError.exportFailed)
                    return
                }

                continuation.resume()
            }
        }

        return outputURL
    }
}
