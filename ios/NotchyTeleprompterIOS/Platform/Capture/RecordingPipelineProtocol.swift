import Foundation

protocol RecordingPipelineProtocol {
    func startRecording() async throws
    func pauseRecording() async throws
    func resumeRecording() async throws
    func stopRecordingAndSave() async throws -> String
    func reset() async
}
