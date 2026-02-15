import Foundation

final class FileStateStore: StateStoreProtocol {
    private let fileURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportURL = baseURL.appendingPathComponent("NotchyTeleprompter", isDirectory: true)
        fileURL = appSupportURL.appendingPathComponent("state.json", isDirectory: false)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> TeleprompterState? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? decoder.decode(TeleprompterState.self, from: data)
    }

    func save(_ state: TeleprompterState) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let data = try encoder.encode(state.clamped())
        try data.write(to: fileURL, options: [.atomic])
    }

    @discardableResult
    func update(_ mutation: (inout TeleprompterState) -> Void) throws -> TeleprompterState {
        var state = load() ?? .defaultState
        mutation(&state)
        state = state.clamped()
        try save(state)
        return state
    }
}
