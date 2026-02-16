import SwiftUI
import UIKit

struct RootCaptureView: View {
    @ObservedObject var controller: AppStateControllerIOS

    var body: some View {
        GeometryReader { geo in
            ZStack {
                cameraLayer
                    .ignoresSafeArea()

                Color.black.opacity(0.18)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topOverlay(geo: geo)
                    Spacer()
                    controlTray
                        .padding(.horizontal, 14)
                        .padding(.bottom, max(10, geo.safeAreaInsets.bottom))
                }

                if let permissionMessage = controller.permissionMessage {
                    permissionOverlay(message: permissionMessage)
                }

                if let status = controller.statusBannerMessage, !status.isEmpty {
                    VStack {
                        Spacer()
                        statusBanner(status)
                            .padding(.bottom, max(130, geo.safeAreaInsets.bottom + 110))
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: status)
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { controller.state.editor.isPresented },
                    set: { controller.setEditorPresented($0) }
                )
            ) {
                EditorSheetView(controller: controller)
                    .notchySheetBackgroundClear()
            }
            .statusBar(hidden: true)
            .onAppear {
                controller.bootstrap()
            }
        }
    }

    private var cameraLayer: some View {
        CameraPreviewView(session: controller.captureSession) { connection in
            controller.configurePreviewConnection(connection)
        }
    }

    @ViewBuilder
    private func topOverlay(geo: GeometryProxy) -> some View {
        if controller.state.overlay.visible {
            TeleprompterOverlayView(
                controller: controller,
                maxWidth: geo.size.width - 24
            )
            .padding(.top, max(2, geo.safeAreaInsets.top + CGFloat(controller.state.overlay.verticalOffsetPx)))
            .transition(.opacity)
        }
    }

    private var controlTray: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                circleIconButton(
                    symbol: controller.state.playback.isPlaying ? "pause.fill" : "play.fill",
                    label: controller.state.playback.isPlaying ? "Pause Teleprompter" : "Play Teleprompter"
                ) {
                    controller.togglePlayback()
                }

                circleIconButton(symbol: "minus", label: "Speed Down") {
                    controller.adjustSpeed(delta: -2)
                }

                circleIconButton(symbol: "arrow.up", label: "Step Script Up") {
                    controller.stepScript(direction: .up)
                }

                circleIconButton(symbol: "arrow.down", label: "Step Script Down") {
                    controller.stepScript(direction: .down)
                }

                Text("\(Int(controller.state.playback.speedPxPerSec.rounded()))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .frame(width: 42)

                circleIconButton(symbol: "plus", label: "Speed Up") {
                    controller.adjustSpeed(delta: 2)
                }

                Spacer(minLength: 6)

                circleIconButton(symbol: "doc.text", label: "Open Script") {
                    controller.setEditorPresented(true)
                }
            }

            HStack(spacing: 10) {
                switch controller.state.recording.status {
                case .idle, .saved, .failed:
                    recordButton(title: "Record", symbol: "record.circle.fill", color: .red) {
                        controller.startRecording()
                    }
                case .recording:
                    recordButton(title: "Pause", symbol: "pause.circle.fill", color: .orange) {
                        controller.pauseRecording()
                    }
                    recordButton(title: "Stop", symbol: "stop.circle.fill", color: .red) {
                        controller.stopRecordingAndSave()
                    }
                case .paused:
                    recordButton(title: "Resume", symbol: "play.circle.fill", color: .green) {
                        controller.resumeRecording()
                    }
                    recordButton(title: "Stop", symbol: "stop.circle.fill", color: .red) {
                        controller.stopRecordingAndSave()
                    }
                case .finalizing:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text("Finalizing…")
                        .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                }

                Spacer(minLength: 8)

                Text(timeLabel(seconds: controller.state.recording.durationSec))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.64))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func circleIconButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func recordButton(title: String, symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.74))
            )
        }
        .buttonStyle(.plain)
        .disabled(controller.commandInFlight)
    }

    private func permissionOverlay(message: String) -> some View {
        VStack(spacing: 12) {
            Text("Permissions Required")
                .font(NotchyTypographyIOS.display(size: 26, weight: .medium))
                .foregroundStyle(Color.white)

            Text(message)
                .font(NotchyTypographyIOS.ui(size: 14, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.82))
                .multilineTextAlignment(.center)

            Text("Open iPhone Settings → Notchy Teleprompter iOS and allow camera + microphone.")
                .font(NotchyTypographyIOS.ui(size: 13, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func statusBanner(_ message: String) -> some View {
        Text(message)
            .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
    }

    private func timeLabel(seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let remaining = total % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }
}

private extension View {
    @ViewBuilder
    func notchySheetBackgroundClear() -> some View {
        if #available(iOS 16.4, *) {
            presentationBackground(.clear)
        } else {
            self
        }
    }
}
