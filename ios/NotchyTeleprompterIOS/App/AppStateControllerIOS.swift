import AVFoundation
import Combine
import Foundation

@MainActor
final class AppStateControllerIOS: ObservableObject {
    @Published private(set) var state: TeleprompterStateIOS
    @Published private(set) var sessionReady = false
    @Published private(set) var permissionMessage: String?
    @Published private(set) var commandInFlight = false
    @Published private(set) var statusBannerMessage: String?

    var captureSession: AVCaptureSession {
        captureManager.session
    }

    private let stateStore: StateStoreProtocol
    private let captureManager: CaptureSessionManaging
    private let recordingPipeline: RecordingPipelineProtocol
    private let ticker: TickerProtocol

    private var maxOffsetPx: Double = 0
    private var hasBootstrapped = false
    private var saveWorkItem: DispatchWorkItem?
    private var offsetPersistCounter = 0
    private var playbackTickAccumulator: Double = 0

    init(
        stateStore: StateStoreProtocol,
        captureManager: CaptureSessionManaging,
        recordingPipeline: RecordingPipelineProtocol,
        ticker: TickerProtocol = DisplayLinkTickerIOS()
    ) {
        self.stateStore = stateStore
        self.captureManager = captureManager
        self.recordingPipeline = recordingPipeline
        self.ticker = ticker

        state = (stateStore.load() ?? .defaultState).clamped()

        ticker.onTick = { [weak self] delta in
            guard let self else { return }
            self.handleTick(deltaSeconds: delta)
        }

        syncTicker()
    }

    func bootstrap() {
        guard !hasBootstrapped else {
            return
        }

        hasBootstrapped = true

        Task {
            let permissions = await captureManager.requestPermissions()
            guard permissions.camera == .authorized else {
                permissionMessage = "Camera access is required. Enable camera permission in Settings."
                return
            }

            guard permissions.microphone == .authorized else {
                permissionMessage = "Microphone access is required. Enable microphone permission in Settings."
                return
            }

            do {
                try await captureManager.prepareSession()
                captureManager.startSession()
                sessionReady = true
                permissionMessage = nil
            } catch {
                permissionMessage = error.localizedDescription
            }
        }
    }

    func togglePlayback() {
        mutate { state in
            let shouldPlay = !state.playback.isPlaying
            if shouldPlay, maxOffsetPx > 0, state.playback.offsetPx >= maxOffsetPx {
                state.playback.offsetPx = 0
            }
            state.playback.isPlaying = shouldPlay
        }
    }

    func setSpeed(_ speed: Double) {
        mutate { state in
            state.playback.speedPxPerSec = speed
        }
    }

    func adjustSpeed(delta: Double) {
        mutate { state in
            state.playback.speedPxPerSec += delta
        }
    }

    func stepScript(direction: ScriptStepDirectionIOS) {
        mutate { state in
            let stepPx = max(8, state.overlay.fontSizePx * state.overlay.lineHeight)
            let nextOffset: Double

            switch direction {
            case .up:
                nextOffset = state.playback.offsetPx - stepPx
            case .down:
                nextOffset = state.playback.offsetPx + stepPx
            }

            state.playback.offsetPx = min(maxOffsetPx, max(0, nextOffset))
        }
    }

    func scrollScript(deltaPx: Double) {
        guard deltaPx != 0 else {
            return
        }

        mutate { state in
            let nextOffset = state.playback.offsetPx + deltaPx
            state.playback.offsetPx = min(maxOffsetPx, max(0, nextOffset))
        }
    }

    func setScriptText(_ text: String) {
        mutate { state in
            state.script.text = text
        }
    }

    func setOverlayVisible(_ isVisible: Bool) {
        mutate { state in
            state.overlay.visible = isVisible
        }
    }

    func setOverlaySize(width: Double, height: Double) {
        mutate { state in
            state.overlay.width = width
            state.overlay.height = height
        }
    }

    func setVerticalPosition(_ value: Double) {
        mutate { state in
            state.overlay.verticalOffsetPx = value
        }
    }

    func setFontSize(_ value: Double) {
        mutate { state in
            state.overlay.fontSizePx = value
        }
    }

    func setLineHeight(_ value: Double) {
        mutate { state in
            state.overlay.lineHeight = value
        }
    }

    func setLetterSpacing(_ value: Double) {
        mutate { state in
            state.overlay.letterSpacingPx = value
        }
    }

    func resetSettingsKeepingScript() {
        mutate { state in
            let script = state.script
            state = .defaultState
            state.script = script
        }
    }

    func setEditorPresented(_ isPresented: Bool) {
        mutate(shouldPersist: false) { state in
            state.editor.isPresented = isPresented
        }
    }

    func setEditorTab(_ tab: EditorTabIOS) {
        mutate { state in
            state.editor.selectedTab = tab
        }
    }

    func resetOffset() {
        mutate { state in
            state.playback.offsetPx = 0
            state.playback.isPlaying = false
        }
    }

    func configurePreviewConnection(_ connection: AVCaptureConnection?) {
        captureManager.configurePreviewConnection(connection)
    }

    func updateScrollBounds(contentHeight: Double, viewportHeight: Double) {
        maxOffsetPx = max(0, contentHeight - viewportHeight)

        if state.playback.offsetPx > maxOffsetPx {
            mutate { state in
                state.playback.offsetPx = maxOffsetPx
                if maxOffsetPx == 0 {
                    state.playback.isPlaying = false
                }
            }
        }
    }

    func startRecording() {
        guard !commandInFlight else {
            return
        }

        commandInFlight = true
        statusBannerMessage = nil

        Task {
            do {
                if !sessionReady {
                    bootstrap()
                }

                try await recordingPipeline.startRecording()

                mutate { state in
                    if maxOffsetPx > 0, state.playback.offsetPx >= maxOffsetPx {
                        state.playback.offsetPx = 0
                    }
                    state.recording.status = .recording
                    state.recording.durationSec = 0
                    state.recording.errorMessage = nil
                    state.recording.lastSavedAssetId = nil
                    state.playback.isPlaying = true
                    state.overlay.visible = true
                }
            } catch {
                mutate { state in
                    state.recording.status = .failed
                    state.recording.errorMessage = error.localizedDescription
                    state.playback.isPlaying = false
                }
                statusBannerMessage = error.localizedDescription
            }

            commandInFlight = false
        }
    }

    func pauseRecording() {
        guard !commandInFlight else {
            return
        }

        commandInFlight = true

        Task {
            do {
                try await recordingPipeline.pauseRecording()
                mutate { state in
                    state.recording.status = .paused
                    state.playback.isPlaying = false
                    state.recording.errorMessage = nil
                }
            } catch {
                mutate { state in
                    state.recording.status = .failed
                    state.recording.errorMessage = error.localizedDescription
                    state.playback.isPlaying = false
                }
                statusBannerMessage = error.localizedDescription
            }

            commandInFlight = false
        }
    }

    func resumeRecording() {
        guard !commandInFlight else {
            return
        }

        commandInFlight = true

        Task {
            do {
                try await recordingPipeline.resumeRecording()
                mutate { state in
                    state.recording.status = .recording
                    state.recording.errorMessage = nil
                    state.playback.isPlaying = true
                }
            } catch {
                mutate { state in
                    state.recording.status = .failed
                    state.recording.errorMessage = error.localizedDescription
                    state.playback.isPlaying = false
                }
                statusBannerMessage = error.localizedDescription
            }

            commandInFlight = false
        }
    }

    func stopRecordingAndSave() {
        guard !commandInFlight else {
            return
        }

        commandInFlight = true

        mutate { state in
            state.recording.status = .finalizing
            state.playback.isPlaying = false
        }

        Task {
            do {
                let assetIdentifier = try await recordingPipeline.stopRecordingAndSave()
                mutate { state in
                    state.recording.status = .saved
                    state.recording.lastSavedAssetId = assetIdentifier
                    state.recording.errorMessage = nil
                }
                statusBannerMessage = "Saved to Photos"
            } catch {
                mutate { state in
                    state.recording.status = .failed
                    state.recording.errorMessage = error.localizedDescription
                    state.playback.isPlaying = false
                }
                statusBannerMessage = error.localizedDescription
            }

            commandInFlight = false
        }
    }

    private func mutate(shouldPersist: Bool = true, _ mutation: (inout TeleprompterStateIOS) -> Void) {
        var next = state
        mutation(&next)
        next = next.clamped()

        state = next
        syncTicker()

        if shouldPersist {
            persistSoon()
        }
    }

    private func syncTicker() {
        if state.playback.isPlaying || state.recording.status == .recording {
            ticker.start()
        } else {
            ticker.stop()
            playbackTickAccumulator = 0
        }
    }

    private func handleTick(deltaSeconds: CFTimeInterval) {
        let safeDelta = max(0, Double(deltaSeconds))

        if state.recording.status == .recording {
            mutate(shouldPersist: false) { state in
                state.recording.durationSec += safeDelta
            }
        }

        guard state.playback.isPlaying else {
            return
        }

        playbackTickAccumulator += safeDelta
        guard playbackTickAccumulator >= (1.0 / 45.0) else {
            return
        }

        let effectiveDelta = playbackTickAccumulator
        playbackTickAccumulator = 0

        let nextOffset = min(
            state.playback.offsetPx + (state.playback.speedPxPerSec * effectiveDelta),
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
        if reachedEnd || offsetPersistCounter >= 20 {
            offsetPersistCounter = 0
            persistNow()
        }
    }

    private func persistSoon() {
        saveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.persistNow()
        }
        saveWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    private func persistNow() {
        do {
            try stateStore.save(state)
        } catch {
            print("[state] Failed to save iOS state: \(error)")
        }
    }
}

enum ScriptStepDirectionIOS {
    case up
    case down
}
