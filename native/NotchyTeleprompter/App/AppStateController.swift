import Combine
import Foundation

@MainActor
final class AppStateController: ObservableObject {
    @Published private(set) var state: TeleprompterState
    @Published private(set) var accessibilityPermissionGranted = false

    var onStateChange: ((TeleprompterState) -> Void)?
    var requestAccessibilityPermissionHandler: (() -> Void)?
    var openEditorTabHandler: ((EditorTab) -> Void)?

    private let stateStore: StateStoreProtocol
    private let migrationService: MigrationServiceProtocol
    private let ticker: DisplayLinkTicker
    private let stylePresetVersionKey = "notchy.stylePresetVersion"

    private var maxOffsetPx: Double = 0
    private var offsetPersistCounter = 0
    private var saveWorkItem: DispatchWorkItem?
    private var playbackTickAccumulator: Double = 0

    init(
        stateStore: StateStoreProtocol,
        migrationService: MigrationServiceProtocol,
        ticker: DisplayLinkTicker = DisplayLinkTicker()
    ) {
        self.stateStore = stateStore
        self.migrationService = migrationService
        self.ticker = ticker

        if let existing = stateStore.load()?.clamped() {
            state = existing
        } else if let imported = migrationService.runIfNeeded(existingState: nil)?.clamped() {
            state = imported
        } else {
            state = TeleprompterState.defaultState
        }

        if !state.migrationCompleted {
            state.migrationCompleted = true
        }

        // Remote bare-key capture is disabled in current UX; keep it off.
        state.keyboard.remoteModeEnabled = false
        state.keyboard.consumeKeysWhenRemote = false

        applyNotchBlendStylePresetIfNeeded()

        try? stateStore.save(state)

        ticker.onTick = { [weak self] deltaSeconds in
            guard let self else { return }
            self.handleTick(deltaSeconds: deltaSeconds)
        }

        syncTicker()
    }

    func togglePlayback() {
        mutate { state in
            let willPlay = !state.playback.isPlaying
            if willPlay, maxOffsetPx > 0, state.playback.offsetPx >= maxOffsetPx {
                state.playback.offsetPx = 0
            }
            if willPlay, !state.panel.visible {
                state.panel.visible = true
            }
            state.playback.isPlaying = willPlay
        }
    }

    func setPlaying(_ isPlaying: Bool) {
        mutate { state in
            if isPlaying, maxOffsetPx > 0, state.playback.offsetPx >= maxOffsetPx {
                state.playback.offsetPx = 0
            }
            if isPlaying, !state.panel.visible {
                state.panel.visible = true
            }
            state.playback.isPlaying = isPlaying
        }
    }

    func setSpeed(_ speedPxPerSec: Double) {
        mutate { state in
            state.playback.speedPxPerSec = speedPxPerSec
        }
    }

    func adjustSpeed(delta: Double) {
        mutate { state in
            state.playback.speedPxPerSec += delta
        }
    }

    func setScriptText(_ text: String) {
        mutate { state in
            state.scriptText = text
        }
    }

    func resetOffset() {
        mutate { state in
            state.playback.offsetPx = 0
            state.playback.isPlaying = false
        }
    }

    func nudgeVertical(direction: VerticalNudgeDirection, step: Double) {
        let delta = direction == .up ? -step : step
        mutate { state in
            state.panel.verticalNudgePx += delta
        }
    }

    func setVerticalPosition(_ verticalPositionPx: Double) {
        mutate { state in
            state.panel.verticalNudgePx = verticalPositionPx
        }
    }

    func setPanelVisible(_ isVisible: Bool) {
        mutate { state in
            state.panel.visible = isVisible
        }
    }

    func togglePanelVisible() {
        mutate { state in
            state.panel.visible.toggle()
        }
    }

    func setPanelSize(width: Double, height: Double) {
        mutate { state in
            state.panel.width = width
            state.panel.height = height
        }
    }

    func setFontSize(_ fontSizePx: Double) {
        mutate { state in
            state.panel.fontSizePx = fontSizePx
        }
    }

    func setLineHeight(_ lineHeight: Double) {
        mutate { state in
            state.panel.lineHeight = lineHeight
        }
    }

    func setLetterSpacing(_ letterSpacingPx: Double) {
        mutate { state in
            state.panel.letterSpacingPx = letterSpacingPx
        }
    }

    func setRemoteModeEnabled(_ enabled: Bool) {
        mutate { state in
            state.keyboard.remoteModeEnabled = enabled
        }
    }

    func setConsumeKeysWhenRemote(_ consumeKeys: Bool) {
        mutate { state in
            state.keyboard.consumeKeysWhenRemote = consumeKeys
        }
    }

    func setAccessibilityPermissionGranted(_ granted: Bool) {
        guard accessibilityPermissionGranted != granted else {
            return
        }
        accessibilityPermissionGranted = granted
    }

    func requestAccessibilityPermission() {
        requestAccessibilityPermissionHandler?()
    }

    func openEditor(tab: EditorTab) {
        openEditorTabHandler?(tab)
    }

    func stepScript(direction: ScriptStepDirection) {
        mutate { state in
            let stepPx = max(8, state.panel.fontSizePx * state.panel.lineHeight)
            let nextOffset: Double
            switch direction {
            case .up:
                nextOffset = state.playback.offsetPx - stepPx
            case .down:
                nextOffset = state.playback.offsetPx + stepPx
            }
            state.playback.offsetPx = min(self.maxOffsetPx, max(0, nextOffset))
        }
    }

    func scrollScript(deltaPx: Double) {
        guard deltaPx != 0 else {
            return
        }

        mutate { state in
            let nextOffset = state.playback.offsetPx + deltaPx
            state.playback.offsetPx = min(self.maxOffsetPx, max(0, nextOffset))
        }
    }

    func scaleSpeed(multiplier: Double) {
        guard multiplier > 0 else {
            return
        }

        mutate { state in
            state.playback.speedPxPerSec *= multiplier
        }
    }

    func resetSettingsKeepingScript() {
        mutate { state in
            let script = state.scriptText
            state = .defaultState
            state.scriptText = script
            state.migrationCompleted = true
        }
    }

    func setEditorFrame(width: Double, height: Double, originX: Double?, originY: Double?) {
        mutate { state in
            state.editor.width = width
            state.editor.height = height
            state.editor.originX = originX
            state.editor.originY = originY
        }
    }

    func updateScrollBounds(contentHeight: Double, viewportHeight: Double) {
        let maxOffset = max(0, contentHeight - viewportHeight)
        maxOffsetPx = maxOffset

        if state.playback.offsetPx > maxOffsetPx {
            mutate { state in
                state.playback.offsetPx = maxOffsetPx
                if maxOffsetPx == 0 {
                    state.playback.isPlaying = false
                }
            }
        }
    }

    private func mutate(shouldPersist: Bool = true, _ mutation: (inout TeleprompterState) -> Void) {
        var nextState = state
        mutation(&nextState)
        nextState = nextState.clamped()

        state = nextState
        onStateChange?(nextState)
        syncTicker()

        if shouldPersist {
            persistSoon()
        }
    }

    private func syncTicker() {
        if state.playback.isPlaying {
            ticker.start()
        } else {
            ticker.stop()
            playbackTickAccumulator = 0
        }
    }

    private func handleTick(deltaSeconds: Double) {
        guard state.playback.isPlaying else {
            return
        }

        let safeDelta = max(0, deltaSeconds)
        playbackTickAccumulator += safeDelta

        // Throttle editor/state redraw pressure on older Macs while keeping motion smooth.
        guard playbackTickAccumulator >= (1.0 / 45.0) else {
            return
        }

        let effectiveDelta = playbackTickAccumulator
        playbackTickAccumulator = 0

        let nextOffset = min(
            state.playback.offsetPx + state.playback.speedPxPerSec * effectiveDelta,
            maxOffsetPx
        )
        let reachedEnd = maxOffsetPx > 0 && nextOffset >= maxOffsetPx

        mutate(shouldPersist: false) { state in
            state.playback.offsetPx = nextOffset
            if reachedEnd {
                state.playback.isPlaying = false
            }
        }

        offsetPersistCounter += 1
        if reachedEnd || offsetPersistCounter >= 18 {
            offsetPersistCounter = 0
            persistNow()
        }
    }

    private func persistSoon() {
        saveWorkItem?.cancel()

        let task = DispatchWorkItem { [weak self] in
            self?.persistNow()
        }

        saveWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: task)
    }

    private func persistNow() {
        do {
            try stateStore.save(state)
        } catch {
            print("[state] Failed to persist state: \(error)")
        }
    }

    private func applyNotchBlendStylePresetIfNeeded() {
        let currentVersion = UserDefaults.standard.integer(forKey: stylePresetVersionKey)
        guard currentVersion < 8 else {
            return
        }

        if currentVersion < 6 {
            // Force a one-time visual reset for the tighter notch-integrated presentation.
            state.panel.width = 358
            state.panel.height = 118
            state.panel.fontSizePx = 14
            state.panel.lineHeight = 1.06
            state.panel.letterSpacingPx = 0
            state.playback.offsetPx = 0
            state.playback.isPlaying = false
        }

        // Always normalize top-anchor default for existing installs.
        state.panel.verticalNudgePx = 0
        state.keyboard.remoteModeEnabled = false
        state.keyboard.consumeKeysWhenRemote = false
        state = state.clamped()

        UserDefaults.standard.set(8, forKey: stylePresetVersionKey)
    }
}

enum VerticalNudgeDirection {
    case up
    case down
}

enum ScriptStepDirection {
    case up
    case down
}
