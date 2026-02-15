import Foundation

final class ElectronMigrationService: MigrationServiceProtocol {
    private let legacyURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        legacyURL = appSupport
            .appendingPathComponent("notchy-mac-app", isDirectory: true)
            .appendingPathComponent("notchy-teleprompter.json", isDirectory: false)
    }

    func runIfNeeded(existingState: TeleprompterState?) -> TeleprompterState? {
        guard existingState == nil else {
            return nil
        }

        guard let data = try? Data(contentsOf: legacyURL) else {
            return nil
        }

        do {
            let legacy = try JSONDecoder().decode(LegacyRoot.self, from: data)
            return mapLegacyState(legacy.state)
        } catch {
            print("[migration] Failed to decode legacy state: \(error)")
            return nil
        }
    }

    private func mapLegacyState(_ legacy: LegacyState) -> TeleprompterState {
        var state = TeleprompterState.defaultState

        if let scriptText = legacy.scriptText, !scriptText.isEmpty {
            state.scriptText = scriptText
        }

        if let playback = legacy.playback {
            state.playback.isPlaying = playback.isPlaying ?? false
            state.playback.speedPxPerSec = playback.speedPxPerSec ?? state.playback.speedPxPerSec
            state.playback.offsetPx = playback.offsetPx ?? 0
        }

        if let window = legacy.prompterWindow {
            state.panel.width = window.width ?? state.panel.width
            state.panel.height = window.height ?? state.panel.height
            state.panel.fontSizePx = window.fontSizePx ?? state.panel.fontSizePx
            state.panel.lineHeight = window.lineHeight ?? state.panel.lineHeight
            state.panel.visible = window.visible ?? state.panel.visible

            let legacyTopOffset = window.topOffsetPx ?? 34
            state.panel.verticalNudgePx = legacyTopOffset >= 24 ? (legacyTopOffset - 34) : legacyTopOffset
        }

        if let editor = legacy.editorWindow {
            state.editor.width = editor.width ?? state.editor.width
            state.editor.height = editor.height ?? state.editor.height
            state.editor.originX = editor.x
            state.editor.originY = editor.y
        }

        state.migrationCompleted = true

        return state.clamped()
    }
}

private struct LegacyRoot: Decodable {
    let state: LegacyState
}

private struct LegacyState: Decodable {
    let scriptText: String?
    let playback: LegacyPlayback?
    let prompterWindow: LegacyPrompterWindow?
    let editorWindow: LegacyEditorWindow?
}

private struct LegacyPlayback: Decodable {
    let isPlaying: Bool?
    let speedPxPerSec: Double?
    let offsetPx: Double?
}

private struct LegacyPrompterWindow: Decodable {
    let width: Double?
    let height: Double?
    let topOffsetPx: Double?
    let fontSizePx: Double?
    let lineHeight: Double?
    let visible: Bool?
}

private struct LegacyEditorWindow: Decodable {
    let width: Double?
    let height: Double?
    let x: Double?
    let y: Double?
}
