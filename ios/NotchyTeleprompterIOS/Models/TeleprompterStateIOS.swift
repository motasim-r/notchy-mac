import Foundation

enum RecordingStatusIOS: String, Codable {
    case idle
    case recording
    case paused
    case finalizing
    case saved
    case failed
}

enum EditorTabIOS: String, Codable, CaseIterable, Identifiable {
    case script
    case settings
    case changelogs

    var id: String { rawValue }
}

struct PlaybackStateIOS: Codable, Equatable {
    var isPlaying: Bool
    var speedPxPerSec: Double
    var offsetPx: Double

    private enum CodingKeys: String, CodingKey {
        case isPlaying
        case speedPxPerSec
        case offsetPx
    }

    init(isPlaying: Bool, speedPxPerSec: Double, offsetPx: Double) {
        self.isPlaying = isPlaying
        self.speedPxPerSec = speedPxPerSec
        self.offsetPx = offsetPx
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterStateIOS.defaultState.playback
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isPlaying = try container.decodeIfPresent(Bool.self, forKey: .isPlaying) ?? defaults.isPlaying
        speedPxPerSec = try container.decodeIfPresent(Double.self, forKey: .speedPxPerSec) ?? defaults.speedPxPerSec
        offsetPx = try container.decodeIfPresent(Double.self, forKey: .offsetPx) ?? defaults.offsetPx
    }
}

struct OverlayStateIOS: Codable, Equatable {
    var width: Double
    var height: Double
    var verticalOffsetPx: Double
    var fontSizePx: Double
    var lineHeight: Double
    var letterSpacingPx: Double
    var visible: Bool

    private enum CodingKeys: String, CodingKey {
        case width
        case height
        case verticalOffsetPx
        case fontSizePx
        case lineHeight
        case letterSpacingPx
        case visible
    }

    init(
        width: Double,
        height: Double,
        verticalOffsetPx: Double,
        fontSizePx: Double,
        lineHeight: Double,
        letterSpacingPx: Double,
        visible: Bool
    ) {
        self.width = width
        self.height = height
        self.verticalOffsetPx = verticalOffsetPx
        self.fontSizePx = fontSizePx
        self.lineHeight = lineHeight
        self.letterSpacingPx = letterSpacingPx
        self.visible = visible
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterStateIOS.defaultState.overlay
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? defaults.width
        height = try container.decodeIfPresent(Double.self, forKey: .height) ?? defaults.height
        verticalOffsetPx = try container.decodeIfPresent(Double.self, forKey: .verticalOffsetPx) ?? defaults.verticalOffsetPx
        fontSizePx = try container.decodeIfPresent(Double.self, forKey: .fontSizePx) ?? defaults.fontSizePx
        lineHeight = try container.decodeIfPresent(Double.self, forKey: .lineHeight) ?? defaults.lineHeight
        letterSpacingPx = try container.decodeIfPresent(Double.self, forKey: .letterSpacingPx) ?? defaults.letterSpacingPx
        visible = try container.decodeIfPresent(Bool.self, forKey: .visible) ?? defaults.visible
    }
}

struct RecordingStateIOS: Codable, Equatable {
    var status: RecordingStatusIOS
    var durationSec: Double
    var lastSavedAssetId: String?
    var errorMessage: String?

    private enum CodingKeys: String, CodingKey {
        case status
        case durationSec
        case lastSavedAssetId
        case errorMessage
    }

    init(status: RecordingStatusIOS, durationSec: Double, lastSavedAssetId: String?, errorMessage: String?) {
        self.status = status
        self.durationSec = durationSec
        self.lastSavedAssetId = lastSavedAssetId
        self.errorMessage = errorMessage
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterStateIOS.defaultState.recording
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(RecordingStatusIOS.self, forKey: .status) ?? defaults.status
        durationSec = try container.decodeIfPresent(Double.self, forKey: .durationSec) ?? defaults.durationSec
        lastSavedAssetId = try container.decodeIfPresent(String.self, forKey: .lastSavedAssetId)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}

struct EditorStateIOS: Codable, Equatable {
    var selectedTab: EditorTabIOS
    var isPresented: Bool

    private enum CodingKeys: String, CodingKey {
        case selectedTab
        case isPresented
    }

    init(selectedTab: EditorTabIOS, isPresented: Bool) {
        self.selectedTab = selectedTab
        self.isPresented = isPresented
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterStateIOS.defaultState.editor
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedTab = try container.decodeIfPresent(EditorTabIOS.self, forKey: .selectedTab) ?? defaults.selectedTab
        isPresented = try container.decodeIfPresent(Bool.self, forKey: .isPresented) ?? defaults.isPresented
    }
}

struct ScriptStateIOS: Codable, Equatable {
    var text: String

    private enum CodingKeys: String, CodingKey {
        case text
    }

    init(text: String) {
        self.text = text
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterStateIOS.defaultState.script
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? defaults.text
    }
}

struct TeleprompterStateIOS: Codable, Equatable {
    var script: ScriptStateIOS
    var playback: PlaybackStateIOS
    var overlay: OverlayStateIOS
    var recording: RecordingStateIOS
    var editor: EditorStateIOS

    private enum CodingKeys: String, CodingKey {
        case script
        case playback
        case overlay
        case recording
        case editor
    }

    static let defaultState = TeleprompterStateIOS(
        script: ScriptStateIOS(
            text: """
Notchy is a native Mac teleprompter designed specifically for the MacBook notch.

It keeps your script directly beside the camera so you can speak naturally, maintain eye contact, and stop glancing down at notes.

Here's how it works: Launch Notchy - the notch-ui appears at the top center of your screen.

Write or paste your script into the separate editor window. Press Space to play or pause scrolling.

Adjust speed, font size, and layout in real time. Notchy auto-saves everything, so your script is always ready when you return. It stays accessible while you record, present, stream, or work.

Who It's For? Content creators & YouTubers, Online coaches & educators, Founders recording demos, Sales teams doing video outreach, Streamers & presenters, Anyone who wants camera-first delivery without memorizing scripts.

Notchy helps you stay on message, sound prepared, and maintain real eye contact - without expensive hardware or awkward screen placement.
"""
        ),
        playback: PlaybackStateIOS(
            isPlaying: false,
            speedPxPerSec: 20,
            offsetPx: 0
        ),
        overlay: OverlayStateIOS(
            width: 334,
            height: 162,
            verticalOffsetPx: 0,
            fontSizePx: 14,
            lineHeight: 1.06,
            letterSpacingPx: 0,
            visible: true
        ),
        recording: RecordingStateIOS(
            status: .idle,
            durationSec: 0,
            lastSavedAssetId: nil,
            errorMessage: nil
        ),
        editor: EditorStateIOS(
            selectedTab: .script,
            isPresented: false
        )
    )

    static let limits = Limits()

    struct Limits {
        let speedMin = 4.0
        let speedMax = 260.0
        let fontSizeMin = 10.0
        let fontSizeMax = 56.0
        let lineHeightMin = 1.0
        let lineHeightMax = 2.2
        let letterSpacingMin = -0.5
        let letterSpacingMax = 8.0
        let widthMin = 200.0
        let widthMax = 390.0
        let heightMin = 90.0
        let heightMax = 320.0
        let verticalOffsetMin = -40.0
        let verticalOffsetMax = 260.0
    }

    func clamped() -> TeleprompterStateIOS {
        var copy = self

        copy.playback.speedPxPerSec = copy.playback.speedPxPerSec.clamped(min: Self.limits.speedMin, max: Self.limits.speedMax)
        copy.playback.offsetPx = max(0, copy.playback.offsetPx)

        copy.overlay.width = copy.overlay.width.clamped(min: Self.limits.widthMin, max: Self.limits.widthMax)
        copy.overlay.height = copy.overlay.height.clamped(min: Self.limits.heightMin, max: Self.limits.heightMax)
        copy.overlay.verticalOffsetPx = copy.overlay.verticalOffsetPx.clamped(min: Self.limits.verticalOffsetMin, max: Self.limits.verticalOffsetMax)
        copy.overlay.fontSizePx = copy.overlay.fontSizePx.clamped(min: Self.limits.fontSizeMin, max: Self.limits.fontSizeMax)
        copy.overlay.lineHeight = copy.overlay.lineHeight.clamped(min: Self.limits.lineHeightMin, max: Self.limits.lineHeightMax)
        copy.overlay.letterSpacingPx = copy.overlay.letterSpacingPx.clamped(min: Self.limits.letterSpacingMin, max: Self.limits.letterSpacingMax)

        if copy.recording.durationSec < 0 {
            copy.recording.durationSec = 0
        }

        return copy
    }

    init(
        script: ScriptStateIOS,
        playback: PlaybackStateIOS,
        overlay: OverlayStateIOS,
        recording: RecordingStateIOS,
        editor: EditorStateIOS
    ) {
        self.script = script
        self.playback = playback
        self.overlay = overlay
        self.recording = recording
        self.editor = editor
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterStateIOS.defaultState
        let container = try decoder.container(keyedBy: CodingKeys.self)
        script = try container.decodeIfPresent(ScriptStateIOS.self, forKey: .script) ?? defaults.script
        playback = try container.decodeIfPresent(PlaybackStateIOS.self, forKey: .playback) ?? defaults.playback
        overlay = try container.decodeIfPresent(OverlayStateIOS.self, forKey: .overlay) ?? defaults.overlay
        recording = try container.decodeIfPresent(RecordingStateIOS.self, forKey: .recording) ?? defaults.recording
        editor = try container.decodeIfPresent(EditorStateIOS.self, forKey: .editor) ?? defaults.editor
    }
}

private extension Double {
    func clamped(min lower: Double, max upper: Double) -> Double {
        Swift.min(upper, Swift.max(lower, self))
    }
}
