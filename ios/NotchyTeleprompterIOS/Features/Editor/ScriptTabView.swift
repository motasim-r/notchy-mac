import SwiftUI

struct ScriptTabView: View {
    @ObservedObject var controller: AppStateControllerIOS

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                playbackCard
                scriptCard
            }
            .padding(16)
        }
    }

    private var playbackCard: some View {
        let countdownValue = controller.playbackCountdownValue
        let playButtonLabel = countdownValue == nil
            ? (controller.state.playback.isPlaying ? "Pause" : "Play")
            : "Starting in \(countdownValue ?? 0)"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                actionButton(playButtonLabel) {
                    controller.togglePlayback()
                }

                actionButton("Reset") {
                    controller.resetOffset()
                }

                Spacer()

                Text(
                    countdownValue == nil
                        ? "Offset \(Int(controller.state.playback.offsetPx.rounded())) px"
                        : "Countdown \(countdownValue ?? 0)"
                )
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            HStack(spacing: 10) {
                Text("Speed")
                    .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.84))

                Slider(
                    value: Binding(
                        get: { controller.state.playback.speedPxPerSec },
                        set: { controller.setSpeed($0) }
                    ),
                    in: TeleprompterStateIOS.limits.speedMin ... TeleprompterStateIOS.limits.speedMax,
                    step: 1
                )
                .tint(Color.white.opacity(0.76))

                Text("\(Int(controller.state.playback.speedPxPerSec.rounded()))")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .frame(width: 44, alignment: .trailing)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var scriptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Script")
                .font(NotchyTypographyIOS.display(size: 22, weight: .medium))
                .foregroundStyle(Color.white)

            TextEditor(text: Binding(
                get: { controller.state.script.text },
                set: { controller.setScriptText($0) }
            ))
            .font(NotchyTypographyIOS.ui(size: 16, weight: .regular))
            .foregroundStyle(Color.white)
            .scrollContentBackground(.hidden)
            .padding(8)
            .frame(minHeight: 220)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.black.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
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
