import SwiftUI

struct EditorView: View {
    @ObservedObject var controller: AppStateController
    @ObservedObject var sessionState: EditorSessionState

    @State private var showResetConfirmation = false

    private var scriptBinding: Binding<String> {
        Binding(
            get: { controller.state.scriptText },
            set: { controller.setScriptText($0) }
        )
    }

    private var appVersionLabel: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "V\(shortVersion) (\(build))"
    }

    @ViewBuilder
    var body: some View {
        let shell = HStack(spacing: 0) {
            leftRail

            Divider()
                .overlay(Color.white.opacity(0.08))

            contentPane
        }
        .frame(minWidth: 760, minHeight: 520)
        .background(rootBackground)
        .ignoresSafeArea(edges: .top)

        if #available(macOS 12.0, *) {
            shell
                .confirmationDialog(
                    "Reset all settings?",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset Settings", role: .destructive) {
                        controller.resetSettingsKeepingScript()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This resets playback, panel size/position, and text settings. Script text is kept.")
                }
        } else {
            shell
                .alert(isPresented: $showResetConfirmation) {
                    Alert(
                        title: Text("Reset all settings?"),
                        message: Text("This resets playback, panel size/position, and text settings. Script text is kept."),
                        primaryButton: .destructive(Text("Reset Settings")) {
                            controller.resetSettingsKeepingScript()
                        },
                        secondaryButton: .cancel()
                    )
                }
        }
    }

    private var rootBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.075, green: 0.078, blue: 0.086),
                    Color(red: 0.066, green: 0.069, blue: 0.078)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.018),
                    Color.clear,
                    Color.white.opacity(0.01)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var leftRail: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(EditorTab.allCases) { tab in
                    EditorRailTabButton(tab: tab, isSelected: sessionState.selectedTab == tab) {
                        sessionState.selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 54)

            Spacer()

            Text(appVersionLabel)
                .font(NotchyBrandTypography.ui(size: 11, weight: .medium))
                .notchyForeground(Color.white.opacity(0.48))
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .frame(width: 194)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    Color.black.opacity(0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var contentPane: some View {
        Group {
            switch sessionState.selectedTab {
            case .script:
                scriptTab
            case .settings:
                settingsTab
            case .shortcuts:
                shortcutsTab
            case .changelogs:
                changelogTab
            }
        }
        .padding(20)
        .padding(.top, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var scriptTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                tabHeader(
                    title: "Script",
                    subtitle: "Keep script and playback controls together for live runs."
                )

                Spacer(minLength: 8)

                if controller.updateAvailable {
                    actionButton(updateButtonTitle, primary: true) {
                        controller.installAvailableUpdate()
                    }
                }
            }

            playbackStrip

            surfaceCard(title: "Script", subtitle: "Edits stream directly into notch-ui.") {
                scriptEditor(binding: scriptBinding)
                    .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            tabHeader(
                title: "Settings",
                subtitle: "Panel geometry and typography tuning."
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    surfaceCard(title: "Panel", subtitle: "Position and size") {
                        sliderControl(
                            title: "Panel Width",
                            valueText: "\(Int(controller.state.panel.width.rounded())) px",
                            value: Binding(
                                get: { controller.state.panel.width },
                                set: { controller.setPanelSize(width: $0, height: controller.state.panel.height) }
                            ),
                            range: TeleprompterState.limits.widthMin ... TeleprompterState.limits.widthMax,
                            step: 1
                        )

                        sliderControl(
                            title: "Panel Height",
                            valueText: "\(Int(controller.state.panel.height.rounded())) px",
                            value: Binding(
                                get: { controller.state.panel.height },
                                set: { controller.setPanelSize(width: controller.state.panel.width, height: $0) }
                            ),
                            range: TeleprompterState.limits.heightMin ... TeleprompterState.limits.heightMax,
                            step: 1
                        )

                        sliderControl(
                            title: "Vertical Position",
                            valueText: "\(Int(controller.state.panel.verticalNudgePx.rounded())) px (0 = top anchor)",
                            value: Binding(
                                get: { controller.state.panel.verticalNudgePx },
                                set: { controller.setVerticalPosition($0) }
                            ),
                            range: TeleprompterState.limits.verticalNudgeMin ... TeleprompterState.limits.verticalNudgeMax,
                            step: 1
                        )
                    }

                    surfaceCard(title: "Text", subtitle: "Readability tuning") {
                        sliderControl(
                            title: "Font Size",
                            valueText: "\(Int(controller.state.panel.fontSizePx.rounded())) px",
                            value: Binding(
                                get: { controller.state.panel.fontSizePx },
                                set: { controller.setFontSize($0) }
                            ),
                            range: TeleprompterState.limits.fontSizeMin ... TeleprompterState.limits.fontSizeMax,
                            step: 1
                        )

                        sliderControl(
                            title: "Line Spacing",
                            valueText: String(format: "%.2f", controller.state.panel.lineHeight),
                            value: Binding(
                                get: { controller.state.panel.lineHeight },
                                set: { controller.setLineHeight($0) }
                            ),
                            range: TeleprompterState.limits.lineHeightMin ... TeleprompterState.limits.lineHeightMax,
                            step: 0.01
                        )

                        sliderControl(
                            title: "Letter Spacing",
                            valueText: String(format: "%.2f px", controller.state.panel.letterSpacingPx),
                            value: Binding(
                                get: { controller.state.panel.letterSpacingPx },
                                set: { controller.setLetterSpacing($0) }
                            ),
                            range: TeleprompterState.limits.letterSpacingMin ... TeleprompterState.limits.letterSpacingMax,
                            step: 0.05
                        )
                    }

                    surfaceCard(title: "Reset", subtitle: "Reset settings, keep script text") {
                        HStack {
                            actionButton("Reset Settings", primary: true) {
                                showResetConfirmation = true
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            tabHeader(
                title: "Shortcuts",
                subtitle: "Focused play/pause plus global modifier shortcuts."
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    surfaceCard(title: "Keyboard Shortcuts", subtitle: "Use Space while Notchy UI is focused, plus global Command shortcuts.") {
                        VStack(alignment: .leading, spacing: 6) {
                            shortcutRow("Space (Notchy UI focused)", "Play/Pause")
                            shortcutRow("Cmd + Shift + Space", "Play/Pause (global fallback)")
                            shortcutRow("Cmd + Shift + Left / Right", "Speed -2 / +2")
                            shortcutRow("Cmd + Shift + Up / Down", "Move script up / down one line")
                            shortcutRow("App Menu → Check for Updates…", "Manual update check")
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var changelogTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            tabHeader(
                title: "Changelogs",
                subtitle: "Tracked updates from V1 to current release."
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    surfaceCard(
                        title: "V2.2.2 Snapshot",
                        subtitle: "This log is now the source of truth for product changes."
                    ) {
                        Text("Rule enabled: every product/UI behavior change should be added here before final builds. Added full app icon rollout and branding pass in 2.2.2.")
                            .font(NotchyBrandTypography.ui(size: 12, weight: .medium))
                            .notchyForeground(Color.white.opacity(0.76))
                    }

                    ForEach(Self.v1ToV2ChangeLogSections) { section in
                        surfaceCard(title: section.title, subtitle: section.subtitle) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(section.items.indices, id: \.self) { index in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(NotchyBrandTypography.ui(size: 12, weight: .bold))
                                            .notchyForeground(Color.white.opacity(0.76))
                                            .padding(.top, 1)

                                        Text(section.items[index])
                                            .font(NotchyBrandTypography.ui(size: 12, weight: .medium))
                                            .notchyForeground(Color.white.opacity(0.82))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var playbackStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                actionButton(controller.state.playback.isPlaying ? "Pause" : "Play", primary: true) {
                    controller.togglePlayback()
                }

                actionButton("Reset to Top") {
                    controller.resetOffset()
                }

                Spacer(minLength: 8)

                if controller.checkingForUpdates {
                    Text("Checking updates…")
                        .font(NotchyBrandTypography.ui(size: 11, weight: .medium))
                        .notchyForeground(Color.white.opacity(0.7))
                } else {
                    Text("Offset")
                        .font(NotchyBrandTypography.ui(size: 11, weight: .medium))
                        .notchyForeground(Color.white.opacity(0.62))

                    Text("\(Int(controller.state.playback.offsetPx.rounded())) px")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .notchyForeground(Color.white.opacity(0.92))
                }
            }

            HStack(spacing: 10) {
                Text("Speed")
                    .font(NotchyBrandTypography.ui(size: 12, weight: .medium))
                    .notchyForeground(Color.white.opacity(0.8))

                Slider(
                    value: Binding(
                        get: { controller.state.playback.speedPxPerSec },
                        set: { controller.setSpeed($0) }
                    ),
                    in: TeleprompterState.limits.speedMin ... TeleprompterState.limits.speedMax,
                    step: 1
                )
                .notchyTint(Color.white.opacity(0.66))

                Text("\(Int(controller.state.playback.speedPxPerSec.rounded())) px/s")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .notchyForeground(Color.white.opacity(0.9))
                    .frame(width: 96, alignment: .trailing)
            }

            if let updateErrorMessage = controller.updateErrorMessage, !updateErrorMessage.isEmpty {
                Text(updateErrorMessage)
                    .font(NotchyBrandTypography.ui(size: 11, weight: .regular))
                    .notchyForeground(Color.white.opacity(0.58))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(cardBackground(cornerRadius: 14))
    }

    @ViewBuilder
    private func scriptEditor(binding: Binding<String>) -> some View {
        if #available(macOS 13.0, *) {
            TextEditor(text: binding)
                .font(NotchyBrandTypography.ui(size: 15, weight: .regular))
                .notchyForeground(.white)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(editorTextBackground)
        } else {
            TextEditor(text: binding)
                .font(NotchyBrandTypography.ui(size: 15, weight: .regular))
                .notchyForeground(.white)
                .padding(12)
                .background(editorTextBackground)
        }
    }

    private var editorTextBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.black.opacity(0.24))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func tabHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(NotchyBrandTypography.display(size: 31, weight: .regular))
                .notchyForeground(.white)

            Text(subtitle)
                .font(NotchyBrandTypography.ui(size: 13, weight: .regular))
                .notchyForeground(Color.white.opacity(0.66))
        }
    }

    private func sliderControl(
        title: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(NotchyBrandTypography.ui(size: 13, weight: .medium))
                    .notchyForeground(Color.white.opacity(0.87))

                Spacer()

                Text(valueText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .notchyForeground(Color.white.opacity(0.72))
            }

            Slider(value: value, in: range, step: step)
                .notchyTint(Color.white.opacity(0.64))
        }
    }

    private func surfaceCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(NotchyBrandTypography.display(size: 21, weight: .medium))
                    .notchyForeground(.white)

                Text(subtitle)
                    .font(NotchyBrandTypography.ui(size: 12, weight: .regular))
                    .notchyForeground(Color.white.opacity(0.68))
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 15))
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(red: 0.1, green: 0.105, blue: 0.115).opacity(0.62))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func actionButton(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(NotchyBrandTypography.ui(size: 12, weight: .medium))
                .notchyForeground(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(primary ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.white.opacity(primary ? 0.18 : 0.1), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func shortcutRow(_ key: String, _ action: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .notchyForeground(Color.white.opacity(0.91))

            Spacer()

            Text(action)
                .font(NotchyBrandTypography.ui(size: 12, weight: .regular))
                .notchyForeground(Color.white.opacity(0.68))
        }
    }

    private var updateButtonTitle: String {
        if let version = controller.updateVersion, !version.isEmpty {
            return "Update \(version)"
        }
        return "Update"
    }

    private static let v1ToV2ChangeLogSections: [ChangeLogSection] = [
        ChangeLogSection(
            title: "Notch UI",
            subtitle: "Notch-adjacent visual behavior and controls",
            items: [
                "Rebuilt notch-ui shape to match true Mac notch shoulder cut-in geometry (outward shoulder carve).",
                "Anchored panel into menu-bar zone with zero-gap blend and pure black background for notch continuity.",
                "Added notch-safe top text inset so lines do not hide behind the physical notch.",
                "Resized panel and typography for tighter camera-adjacent readability and centered text alignment.",
                "Moved controls to hover behavior and then upgraded to a slick black slide-in tray for visibility on any background.",
                "Tray now includes Play/Pause (first), Script, Shortcuts, and Minimize actions.",
                "Default vertical position is now normalized to 0 px (top anchor) across existing installs.",
                "Top corners automatically become rounded whenever Vertical Position is positive."
            ]
        ),
        ChangeLogSection(
            title: "Editor UI",
            subtitle: "Design system and workflow changes",
            items: [
                "Redesigned editor into dark-glass left-rail tabs inspired by modern productivity apps.",
                "Created dedicated tabs: Script, Settings, Shortcuts, and now Changelogs.",
                "Adopted brand typography stack: Season Serif for section headings and Season Sans for body/control text.",
                "Script tab keeps playback controls at top with live speed and offset feedback.",
                "Settings tab uses sliders for panel width, height, vertical position, font size, line spacing, and letter spacing.",
                "Removed vertical quick-step buttons once slider-based vertical control became clear.",
                "Reset Settings flow preserves script text while resetting visual/playback preferences."
            ]
        ),
        ChangeLogSection(
            title: "Playback and Scrolling",
            subtitle: "Reading control and movement behavior",
            items: [
                "Fixed startup playback reliability issue where play required a panel resize before running.",
                "Added direct notch-ui mouse/trackpad scrolling: two-finger or wheel moves script offset in real time.",
                "Downward scroll advances script naturally (text moves upward), with clamped boundaries.",
                "Play from editor now auto-restores notch-ui if it was minimized/hidden.",
                "End-of-script behavior keeps auto-pause and reset-to-top flow.",
                "Playback state updates are throttled to reduce UI lag on older Mac hardware."
            ]
        ),
        ChangeLogSection(
            title: "Keyboard and Input",
            subtitle: "Shortcut mapping simplification",
            items: [
                "Set global shortcut mapping to Cmd+Shift+Left/Right for speed and Cmd+Shift+Up/Down for line stepping.",
                "Removed bracket-based vertical-position shortcuts in favor of script movement shortcuts.",
                "Removed Remote Mode toggle complexity from UI and runtime behavior for a cleaner default.",
                "Focused Space key behavior remains for play/pause when notch-ui/app is focused."
            ]
        ),
        ChangeLogSection(
            title: "App Lifecycle and Distribution",
            subtitle: "Platform, persistence, and usability",
            items: [
                "Superseded Electron path with native Swift/AppKit + SwiftUI implementation for notch-accurate behavior.",
                "Kept Dock presence for easier app discovery, activation, and quitting.",
                "Maintained persistent local state across launches for script and settings.",
                "Added clearer hide/show controls to avoid confusion between hiding notch-ui and quitting app.",
                "Prepared signing/notarization pipeline for public distribution flow.",
                "Installer DMG now shows a centered drag-to-install instruction message for first-time users.",
                "Expanded compatibility baseline to support macOS 11.0+ with UI fallbacks for older SwiftUI runtimes.",
                "Editor tab sections now use lazy rendering for smoother tab switching.",
                "Integrated Sparkle auto-update plumbing with update detection, in-app update CTA, and a Check for Updates menu action.",
                "Added a repo-level Brand Guidelines spec to keep app/editor/website styling consistent."
            ]
        )
    ]
}

private struct ChangeLogSection: Identifiable {
    let title: String
    let subtitle: String
    let items: [String]

    var id: String { title }
}

private struct EditorRailTabButton: View {
    let tab: EditorTab
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 15)

                VStack(alignment: .leading, spacing: 1) {
                    Text(tab.title)
                        .font(NotchyBrandTypography.ui(size: 13, weight: .medium))

                    Text(tab.subtitle)
                        .font(NotchyBrandTypography.ui(size: 10, weight: .regular))
                        .notchyForeground(Color.white.opacity(isSelected ? 0.74 : 0.52))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .notchyForeground(Color.white.opacity(isSelected ? 0.96 : 0.78))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.14) : Color.white.opacity(isHovering ? 0.06 : 0.01))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(isSelected ? 0.2 : 0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

private enum NotchyBrandTypography {
    private static let seasonSerifRegular = "SeasonSerif-Regular-TRIAL"
    private static let seasonSerifMedium = "SeasonSerif-Medium-TRIAL"
    private static let seasonSerifBold = "SeasonSerif-Bold-TRIAL"
    private static let seasonSansRegular = "SeasonSans-Regular-TRIAL"
    private static let seasonSansMedium = "SeasonSans-Medium-TRIAL"
    private static let seasonSansBold = "SeasonSans-Bold-TRIAL"

    static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold, .heavy, .semibold:
            fontName = seasonSerifBold
        case .medium:
            fontName = seasonSerifMedium
        default:
            fontName = seasonSerifRegular
        }
        return .custom(fontName, size: size)
    }

    static func ui(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold, .heavy, .semibold:
            fontName = seasonSansBold
        case .medium:
            fontName = seasonSansMedium
        default:
            fontName = seasonSansRegular
        }
        return .custom(fontName, size: size)
    }
}

private extension View {
    @ViewBuilder
    func notchyForeground(_ color: Color) -> some View {
        if #available(macOS 12.0, *) {
            foregroundStyle(color)
        } else {
            foregroundColor(color)
        }
    }

    @ViewBuilder
    func notchyTint(_ color: Color) -> some View {
        if #available(macOS 13.0, *) {
            tint(color)
        } else {
            accentColor(color)
        }
    }
}
