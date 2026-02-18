import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var controller: AppStateControllerIOS

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                panelCard
                visibilityCard
                textCard
                resetCard
            }
            .padding(16)
        }
    }

    private var panelCard: some View {
        settingsCard(title: "Panel") {
            sliderRow(
                title: "Width",
                valueText: "\(Int(controller.state.overlay.width.rounded())) px",
                value: Binding(
                    get: { controller.state.overlay.width },
                    set: { controller.setOverlaySize(width: $0, height: controller.state.overlay.height) }
                ),
                range: TeleprompterStateIOS.limits.widthMin ... TeleprompterStateIOS.limits.widthMax,
                step: 1
            )

            sliderRow(
                title: "Height",
                valueText: "\(Int(controller.state.overlay.height.rounded())) px",
                value: Binding(
                    get: { controller.state.overlay.height },
                    set: { controller.setOverlaySize(width: controller.state.overlay.width, height: $0) }
                ),
                range: TeleprompterStateIOS.limits.heightMin ... TeleprompterStateIOS.limits.heightMax,
                step: 1
            )

            sliderRow(
                title: "Vertical Position",
                valueText: "\(Int(controller.state.overlay.verticalOffsetPx.rounded())) px",
                value: Binding(
                    get: { controller.state.overlay.verticalOffsetPx },
                    set: { controller.setVerticalPosition($0) }
                ),
                range: TeleprompterStateIOS.limits.verticalOffsetMin ... TeleprompterStateIOS.limits.verticalOffsetMax,
                step: 1
            )
        }
    }

    private var textCard: some View {
        settingsCard(title: "Text") {
            sliderRow(
                title: "Font Size",
                valueText: "\(Int(controller.state.overlay.fontSizePx.rounded())) px",
                value: Binding(
                    get: { controller.state.overlay.fontSizePx },
                    set: { controller.setFontSize($0) }
                ),
                range: TeleprompterStateIOS.limits.fontSizeMin ... TeleprompterStateIOS.limits.fontSizeMax,
                step: 1
            )

            sliderRow(
                title: "Line Height",
                valueText: String(format: "%.2f", controller.state.overlay.lineHeight),
                value: Binding(
                    get: { controller.state.overlay.lineHeight },
                    set: { controller.setLineHeight($0) }
                ),
                range: TeleprompterStateIOS.limits.lineHeightMin ... TeleprompterStateIOS.limits.lineHeightMax,
                step: 0.01
            )

            sliderRow(
                title: "Letter Spacing",
                valueText: String(format: "%.2f px", controller.state.overlay.letterSpacingPx),
                value: Binding(
                    get: { controller.state.overlay.letterSpacingPx },
                    set: { controller.setLetterSpacing($0) }
                ),
                range: TeleprompterStateIOS.limits.letterSpacingMin ... TeleprompterStateIOS.limits.letterSpacingMax,
                step: 0.05
            )
        }
    }

    private var visibilityCard: some View {
        settingsCard(title: "Visibility") {
            Toggle(
                "Show Notchy Overlay",
                isOn: Binding(
                    get: { controller.state.overlay.visible },
                    set: { controller.setOverlayVisible($0) }
                )
            )
            .toggleStyle(.switch)
            .tint(Color(red: 0.05, green: 0.08, blue: 0.16))
            .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.86))
        }
    }

    private var resetCard: some View {
        settingsCard(title: "Reset") {
            Button {
                controller.resetSettingsKeepingScript()
            } label: {
                Text("Reset Settings (Keep Script)")
                    .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(NotchyTypographyIOS.display(size: 21, weight: .medium))
                .foregroundStyle(Color.white)
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func sliderRow(
        title: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.86))

                Spacer()

                Text(valueText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.75))
            }

            Slider(value: value, in: range, step: step)
                .tint(Color.white.opacity(0.75))
        }
    }
}
