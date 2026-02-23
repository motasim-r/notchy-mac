import Foundation

enum DisplayTargetMode: String, Codable {
    case builtInPreferred
}

struct PlaybackState: Codable, Equatable {
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
        let defaults = TeleprompterState.defaultState.playback
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isPlaying = try container.decodeIfPresent(Bool.self, forKey: .isPlaying) ?? defaults.isPlaying
        speedPxPerSec = try container.decodeIfPresent(Double.self, forKey: .speedPxPerSec) ?? defaults.speedPxPerSec
        offsetPx = try container.decodeIfPresent(Double.self, forKey: .offsetPx) ?? defaults.offsetPx
    }
}

struct PanelState: Codable, Equatable {
    var width: Double
    var height: Double
    var verticalNudgePx: Double
    var backgroundOpacity: Double
    var fontSizePx: Double
    var lineHeight: Double
    var letterSpacingPx: Double
    var visible: Bool
    var excludeFromCapture: Bool
    var showTimer: Bool

    private enum CodingKeys: String, CodingKey {
        case width
        case height
        case verticalNudgePx
        case backgroundOpacity
        case fontSizePx
        case lineHeight
        case letterSpacingPx
        case visible
        case excludeFromCapture
        case showTimer
    }

    init(
        width: Double,
        height: Double,
        verticalNudgePx: Double,
        backgroundOpacity: Double,
        fontSizePx: Double,
        lineHeight: Double,
        letterSpacingPx: Double,
        visible: Bool,
        excludeFromCapture: Bool,
        showTimer: Bool
    ) {
        self.width = width
        self.height = height
        self.verticalNudgePx = verticalNudgePx
        self.backgroundOpacity = backgroundOpacity
        self.fontSizePx = fontSizePx
        self.lineHeight = lineHeight
        self.letterSpacingPx = letterSpacingPx
        self.visible = visible
        self.excludeFromCapture = excludeFromCapture
        self.showTimer = showTimer
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterState.defaultState.panel
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? defaults.width
        height = try container.decodeIfPresent(Double.self, forKey: .height) ?? defaults.height
        verticalNudgePx = try container.decodeIfPresent(Double.self, forKey: .verticalNudgePx) ?? defaults.verticalNudgePx
        backgroundOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOpacity) ?? defaults.backgroundOpacity
        fontSizePx = try container.decodeIfPresent(Double.self, forKey: .fontSizePx) ?? defaults.fontSizePx
        lineHeight = try container.decodeIfPresent(Double.self, forKey: .lineHeight) ?? defaults.lineHeight
        letterSpacingPx = try container.decodeIfPresent(Double.self, forKey: .letterSpacingPx) ?? defaults.letterSpacingPx
        visible = try container.decodeIfPresent(Bool.self, forKey: .visible) ?? defaults.visible
        excludeFromCapture = try container.decodeIfPresent(Bool.self, forKey: .excludeFromCapture) ?? defaults.excludeFromCapture
        showTimer = try container.decodeIfPresent(Bool.self, forKey: .showTimer) ?? defaults.showTimer
    }
}

struct EditorState: Codable, Equatable {
    var width: Double
    var height: Double
    var originX: Double?
    var originY: Double?

    private enum CodingKeys: String, CodingKey {
        case width
        case height
        case originX
        case originY
    }

    init(width: Double, height: Double, originX: Double?, originY: Double?) {
        self.width = width
        self.height = height
        self.originX = originX
        self.originY = originY
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterState.defaultState.editor
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? defaults.width
        height = try container.decodeIfPresent(Double.self, forKey: .height) ?? defaults.height
        originX = try container.decodeIfPresent(Double.self, forKey: .originX)
        originY = try container.decodeIfPresent(Double.self, forKey: .originY)
    }
}

struct KeyboardControlState: Codable, Equatable {
    var remoteModeEnabled: Bool
    var consumeKeysWhenRemote: Bool

    private enum CodingKeys: String, CodingKey {
        case remoteModeEnabled
        case consumeKeysWhenRemote
    }

    init(remoteModeEnabled: Bool, consumeKeysWhenRemote: Bool) {
        self.remoteModeEnabled = remoteModeEnabled
        self.consumeKeysWhenRemote = consumeKeysWhenRemote
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterState.defaultState.keyboard
        let container = try decoder.container(keyedBy: CodingKeys.self)
        remoteModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .remoteModeEnabled) ?? defaults.remoteModeEnabled
        consumeKeysWhenRemote = try container.decodeIfPresent(Bool.self, forKey: .consumeKeysWhenRemote) ?? defaults.consumeKeysWhenRemote
    }
}

struct TeleprompterState: Codable, Equatable {
    var scriptText: String
    var playback: PlaybackState
    var panel: PanelState
    var editor: EditorState
    var keyboard: KeyboardControlState
    var displayMode: DisplayTargetMode
    var migrationCompleted: Bool

    private enum CodingKeys: String, CodingKey {
        case scriptText
        case playback
        case panel
        case editor
        case keyboard
        case displayMode
        case migrationCompleted
    }

    static let defaultState = TeleprompterState(
        scriptText: "Notchy is a native Mac teleprompter designed specifically for the MacBook notch.\\n\\nIt keeps your script directly beside the camera so you can speak naturally, maintain eye contact, and stop glancing down at notes.\\n\\nHere’s how it works: Launch Notchy – the notch-ui appears at the top center of your screen.\\n\\nWrite or paste your script into the separate editor window. Press Space to play or pause scrolling.\\n\\nAdjust speed, font size, and layout in real time. Notchy auto-saves everything, so your script is always ready when you return. It stays accessible while you record, present, stream, or work.\\n\\nWho It’s For? Content creators & YouTubers, Online coaches & educators, Founders recording demos, Sales teams doing video outreach, Streamers & presenters, Anyone who wants camera-first delivery without memorizing scripts\\n\\nNotchy helps you stay on message, sound prepared, and maintain real eye contact – without expensive hardware or awkward screen placement.",
        playback: PlaybackState(
            isPlaying: false,
            speedPxPerSec: 20,
            offsetPx: 0
        ),
        panel: PanelState(
            width: 358,
            height: 118,
            verticalNudgePx: 0,
            backgroundOpacity: 0.95,
            fontSizePx: 14,
            lineHeight: 1.06,
            letterSpacingPx: 0,
            visible: true,
            excludeFromCapture: true,
            showTimer: false
        ),
        editor: EditorState(
            width: 860,
            height: 700,
            originX: nil,
            originY: nil
        ),
        keyboard: KeyboardControlState(
            remoteModeEnabled: false,
            consumeKeysWhenRemote: false
        ),
        displayMode: .builtInPreferred,
        migrationCompleted: false
    )

    static let limits = Limits()

    struct Limits {
        let speedMin = 4.0
        let speedMax = 260.0
        let fontSizeMin = 10.0
        let fontSizeMax = 110.0
        let lineHeightMin = 1.0
        let lineHeightMax = 2.2
        let letterSpacingMin = -0.5
        let letterSpacingMax = 8.0
        let widthMin = 220.0
        let widthMax = 1400.0
        let heightMin = 90.0
        let heightMax = 600.0
        let verticalNudgeMin = -70.0
        let verticalNudgeMax = 220.0
        let backgroundOpacityMin = 0.3
        let backgroundOpacityMax = 1.0
        let editorWidthMin = 680.0
        let editorHeightMin = 520.0
    }

    func clamped() -> TeleprompterState {
        var copy = self

        copy.playback.speedPxPerSec = copy.playback.speedPxPerSec.clamped(
            min: Self.limits.speedMin,
            max: Self.limits.speedMax
        )
        copy.playback.offsetPx = max(0, copy.playback.offsetPx)

        copy.panel.width = copy.panel.width.clamped(min: Self.limits.widthMin, max: Self.limits.widthMax)
        copy.panel.height = copy.panel.height.clamped(min: Self.limits.heightMin, max: Self.limits.heightMax)
        copy.panel.verticalNudgePx = copy.panel.verticalNudgePx.clamped(
            min: Self.limits.verticalNudgeMin,
            max: Self.limits.verticalNudgeMax
        )
        copy.panel.backgroundOpacity = copy.panel.backgroundOpacity.clamped(
            min: Self.limits.backgroundOpacityMin,
            max: Self.limits.backgroundOpacityMax
        )
        copy.panel.fontSizePx = copy.panel.fontSizePx.clamped(
            min: Self.limits.fontSizeMin,
            max: Self.limits.fontSizeMax
        )
        copy.panel.lineHeight = copy.panel.lineHeight.clamped(
            min: Self.limits.lineHeightMin,
            max: Self.limits.lineHeightMax
        )
        copy.panel.letterSpacingPx = copy.panel.letterSpacingPx.clamped(
            min: Self.limits.letterSpacingMin,
            max: Self.limits.letterSpacingMax
        )

        copy.editor.width = max(Self.limits.editorWidthMin, copy.editor.width)
        copy.editor.height = max(Self.limits.editorHeightMin, copy.editor.height)

        return copy
    }

    init(
        scriptText: String,
        playback: PlaybackState,
        panel: PanelState,
        editor: EditorState,
        keyboard: KeyboardControlState,
        displayMode: DisplayTargetMode,
        migrationCompleted: Bool
    ) {
        self.scriptText = scriptText
        self.playback = playback
        self.panel = panel
        self.editor = editor
        self.keyboard = keyboard
        self.displayMode = displayMode
        self.migrationCompleted = migrationCompleted
    }

    init(from decoder: Decoder) throws {
        let defaults = TeleprompterState.defaultState
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scriptText = try container.decodeIfPresent(String.self, forKey: .scriptText) ?? defaults.scriptText
        playback = try container.decodeIfPresent(PlaybackState.self, forKey: .playback) ?? defaults.playback
        panel = try container.decodeIfPresent(PanelState.self, forKey: .panel) ?? defaults.panel
        editor = try container.decodeIfPresent(EditorState.self, forKey: .editor) ?? defaults.editor
        keyboard = try container.decodeIfPresent(KeyboardControlState.self, forKey: .keyboard) ?? defaults.keyboard
        displayMode = try container.decodeIfPresent(DisplayTargetMode.self, forKey: .displayMode) ?? defaults.displayMode
        migrationCompleted = try container.decodeIfPresent(Bool.self, forKey: .migrationCompleted) ?? defaults.migrationCompleted
    }
}

private extension Double {
    func clamped(min lowerBound: Double, max upperBound: Double) -> Double {
        Swift.min(upperBound, Swift.max(lowerBound, self))
    }
}
