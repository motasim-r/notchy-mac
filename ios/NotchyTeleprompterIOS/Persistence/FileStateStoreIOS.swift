import Foundation

final class FileStateStoreIOS: StateStoreProtocol {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let stateURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let folderURL = appSupport.appendingPathComponent("NotchyTeleprompterIOS", isDirectory: true)
        self.stateURL = folderURL.appendingPathComponent("state.json", isDirectory: false)
    }

    func load() -> TeleprompterStateIOS? {
        guard fileManager.fileExists(atPath: stateURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: stateURL)
            return try decoder.decode(TeleprompterStateIOS.self, from: data)
        } catch {
            print("[state] Failed to load state: \(error)")
            return nil
        }
    }

    func save(_ state: TeleprompterStateIOS) throws {
        let folderURL = stateURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        let data = try encoder.encode(state)
        try data.write(to: stateURL, options: [.atomic])
    }

    @discardableResult
    func update(_ mutation: (inout TeleprompterStateIOS) -> Void) throws -> TeleprompterStateIOS {
        var state = load() ?? .defaultState
        mutation(&state)
        try save(state)
        return state
    }
}
