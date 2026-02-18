import AppKit
import SwiftUI

struct TeleprompterPanelView: View {
    @ObservedObject var controller: AppStateController

    @State private var viewportHeight: CGFloat = 0
    @State private var isHoveringPanel = false
    @State private var isHoveringControlTray = false
    @State private var hoverCollapseWorkItem: DispatchWorkItem?

    private let topShoulderRadius: CGFloat = 37
    private let bottomCornerRadius: CGFloat = 14
    private let detachedTopCornerRadius: CGFloat = 16
    private let notchTextSafeTopInset: CGFloat = 30

    private var isControlTrayExpanded: Bool {
        isHoveringPanel || isHoveringControlTray
    }

    var body: some View {
        ZStack {
            panelBackground

            viewport
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    controlTray
                        .opacity(isControlTrayExpanded ? 1 : 0)
                        .offset(x: isControlTrayExpanded ? 0 : 14)
                        .allowsHitTesting(isControlTrayExpanded)
                }
                .padding(.trailing, 6)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                isHoveringPanel = true
                cancelHoverCollapse()
            } else {
                isHoveringPanel = false
                scheduleHoverCollapse()
            }
        }
        .animation(.easeInOut(duration: 0.16), value: isControlTrayExpanded)
    }

    @ViewBuilder
    private var panelBackground: some View {
        if controller.state.panel.verticalNudgePx > 0.5 {
            DetachedRoundedPanelShape(
                topRadius: detachedTopCornerRadius,
                bottomRadius: bottomCornerRadius
            )
            .fill(Color.black)
        } else {
            NotchReferencePanelShape(
                topRadius: topShoulderRadius,
                bottomRadius: bottomCornerRadius
            )
            .fill(Color.black)
        }
    }

    private var viewport: some View {
        GeometryReader { geo in
            let textColumnWidth = max(120, geo.size.width - 40)
            let contentTextHeight = measuredTextHeight(textColumnWidth: textColumnWidth)
            let totalContentHeight = notchTextSafeTopInset + contentTextHeight

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: notchTextSafeTopInset)

                    scriptTextView(textColumnWidth: textColumnWidth)
                }
                .offset(y: -controller.state.playback.offsetPx)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .onAppear {
                viewportHeight = geo.size.height
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: viewportHeight)
                DispatchQueue.main.async {
                    controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: geo.size.height)
                }
            }
            .onChange(of: geo.size.height) { newHeight in
                viewportHeight = newHeight
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: viewportHeight)
            }
            .onChange(of: geo.size.width) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: viewportHeight)
            }
            .onChange(of: controller.state.scriptText) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: viewportHeight)
            }
            .onChange(of: controller.state.panel.fontSizePx) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: viewportHeight)
            }
            .onChange(of: controller.state.panel.lineHeight) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: viewportHeight)
            }
            .onChange(of: controller.state.panel.letterSpacingPx) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: viewportHeight)
            }
        }
    }

    private var controlTray: some View {
        VStack(spacing: 6) {
            iconControlButton(
                symbolName: controller.state.playback.isPlaying ? "pause.fill" : "play.fill",
                accessibilityLabel: controller.state.playback.isPlaying ? "Pause" : "Play"
            ) {
                controller.togglePlayback()
            }

            iconControlButton(symbolName: "doc.text", accessibilityLabel: "Open Script") {
                controller.openEditor(tab: .script)
            }

            iconControlButton(symbolName: "keyboard", accessibilityLabel: "Open Shortcuts") {
                controller.openEditor(tab: .shortcuts)
            }

            iconControlButton(symbolName: "minus", accessibilityLabel: "Hide Notch UI") {
                controller.setPanelVisible(false)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
                )
        )
        .shadow(color: Color.black.opacity(0.42), radius: 8, x: 0, y: 2)
        .onHover { hovering in
            if hovering {
                isHoveringControlTray = true
                cancelHoverCollapse()
            } else {
                isHoveringControlTray = false
                scheduleHoverCollapse()
            }
        }
    }

    private func iconControlButton(
        symbolName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 9, weight: .semibold))
                .notchyForeground(Color.white.opacity(0.9))
                .frame(width: 16, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color.white.opacity(0.28), lineWidth: 0.8)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func scriptTextView(textColumnWidth: CGFloat) -> some View {
        let baseText = Text(controller.state.scriptText.isEmpty ? " " : controller.state.scriptText)
            .font(.system(
                size: controller.state.panel.fontSizePx,
                weight: .black,
                design: .monospaced
            ))
            .lineSpacing((controller.state.panel.lineHeight - 1) * controller.state.panel.fontSizePx)
            .notchyForeground(Color.white)
            .multilineTextAlignment(.center)
            .frame(width: textColumnWidth, alignment: .center)
            .fixedSize(horizontal: false, vertical: true)

        if #available(macOS 13.0, *) {
            baseText
                .kerning(controller.state.panel.letterSpacingPx)
        } else {
            baseText
        }
    }

    private func measuredTextHeight(textColumnWidth: CGFloat) -> CGFloat {
        let text = controller.state.scriptText.isEmpty ? " " : controller.state.scriptText
        let fontSize = controller.state.panel.fontSizePx
        let lineSpacing = (controller.state.panel.lineHeight - 1) * fontSize

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .black),
            .paragraphStyle: paragraph,
            .kern: controller.state.panel.letterSpacingPx
        ]

        let attributed = NSAttributedString(string: text, attributes: attributes)
        let bounds = attributed.boundingRect(
            with: NSSize(width: max(1, textColumnWidth), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )

        return ceil(bounds.height)
    }

    private func cancelHoverCollapse() {
        hoverCollapseWorkItem?.cancel()
        hoverCollapseWorkItem = nil
    }

    private func scheduleHoverCollapse() {
        hoverCollapseWorkItem?.cancel()
        let task = DispatchWorkItem {
            if !isHoveringPanel && !isHoveringControlTray {
                isHoveringPanel = false
                isHoveringControlTray = false
            }
        }
        hoverCollapseWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: task)
    }
}

private struct NotchReferencePanelShape: Shape {
    let topRadius: CGFloat
    let bottomRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let top = max(0, min(topRadius, min(rect.width * 0.32, rect.height * 0.55)))
        let bottom = max(0, min(bottomRadius, min(rect.width * 0.25, rect.height * 0.5)))
        let leftWallX = rect.minX + top
        let rightWallX = rect.maxX - top
        let shoulderY = rect.minY + top
        var path = Path()

        // Top seam is full-width; shoulders carve outward from inset side walls.
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Top-right outward shoulder into inset right wall.
        path.addQuadCurve(
            to: CGPoint(x: rightWallX, y: shoulderY),
            control: CGPoint(x: rightWallX, y: rect.minY)
        )

        // Inset right wall into rounded bottom-right corner.
        path.addLine(to: CGPoint(x: rightWallX, y: rect.maxY - bottom))
        path.addQuadCurve(
            to: CGPoint(x: rightWallX - bottom, y: rect.maxY),
            control: CGPoint(x: rightWallX, y: rect.maxY)
        )

        // Bottom edge and rounded bottom-left corner.
        path.addLine(to: CGPoint(x: leftWallX + bottom, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: leftWallX, y: rect.maxY - bottom),
            control: CGPoint(x: leftWallX, y: rect.maxY)
        )

        // Inset left wall into top-left outward shoulder.
        path.addLine(to: CGPoint(x: leftWallX, y: shoulderY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: leftWallX, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }
}

private struct DetachedRoundedPanelShape: Shape {
    let topRadius: CGFloat
    let bottomRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let top = max(0, min(topRadius, min(rect.width * 0.2, rect.height * 0.45)))
        let bottom = max(0, min(bottomRadius, min(rect.width * 0.2, rect.height * 0.45)))
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + top, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + top),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottom))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - bottom, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + bottom, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bottom),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + top))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + top, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()

        return path
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
}
