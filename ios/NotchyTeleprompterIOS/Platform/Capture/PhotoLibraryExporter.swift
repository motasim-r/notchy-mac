import Photos

protocol PhotoLibraryExporting {
    func saveVideo(at fileURL: URL) async throws -> String
}

enum PhotoLibraryExportError: LocalizedError {
    case permissionDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo Library permission is required to save recordings."
        case .saveFailed:
            return "Unable to save the recording to Photos."
        }
    }
}

final class PhotoLibraryExporter: PhotoLibraryExporting {
    func saveVideo(at fileURL: URL) async throws -> String {
        let status = await requestAuthorizationIfNeeded()
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryExportError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            var placeholderId: String?

            PHPhotoLibrary.shared().performChanges {
                if let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL) {
                    placeholderId = request.placeholderForCreatedAsset?.localIdentifier
                }
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard success, let placeholderId else {
                    continuation.resume(throwing: PhotoLibraryExportError.saveFailed)
                    return
                }

                continuation.resume(returning: placeholderId)
            }
        }
    }

    private func requestAuthorizationIfNeeded() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        return current
    }
}
