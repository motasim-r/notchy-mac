import SwiftUI
import UIKit

struct TeleprompterOverlayView: View {
    @ObservedObject var controller: AppStateControllerIOS
    let maxWidth: CGFloat

    @State private var viewportHeight: CGFloat = 0
    @State private var lastDragY: CGFloat = 0

    private let topShoulderRadius: CGFloat = 34
    private let bottomCornerRadius: CGFloat = 16
    private let detachedTopCornerRadius: CGFloat = 16
    private let notchSafeTopInset: CGFloat = 34

    private var overlayWidth: CGFloat {
        min(CGFloat(controller.state.overlay.width), maxWidth)
    }

    private var isDetachedShape: Bool {
        controller.state.overlay.verticalOffsetPx > 0.5
    }

    private var overlayShape: OverlayChromeShape {
        OverlayChromeShape(
            isDetached: isDetachedShape,
            notchTopRadius: topShoulderRadius,
            detachedTopRadius: detachedTopCornerRadius,
            bottomRadius: bottomCornerRadius
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                overlayShape
                    .fill(Color.black.opacity(0.92))

                viewport
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(width: overlayWidth, height: CGFloat(controller.state.overlay.height))
            .clipShape(overlayShape)
            .overlay(
                overlayShape
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onAppear {
                viewportHeight = geometry.size.height
            }
            .onChange(of: geometry.size.height) { newHeight in
                viewportHeight = newHeight
            }
        }
        .frame(width: overlayWidth, height: CGFloat(controller.state.overlay.height))
        .opacity(controller.state.overlay.visible ? 1 : 0)
    }

    private var viewport: some View {
        GeometryReader { geo in
            let textColumnWidth = max(120, geo.size.width - 24)
            let contentTextHeight = measuredTextHeight(textColumnWidth: textColumnWidth)
            let totalContentHeight = max(geo.size.height, notchSafeTopInset + contentTextHeight)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: notchSafeTopInset)

                    scriptTextView(textColumnWidth: textColumnWidth)
                }
                .offset(y: -controller.state.playback.offsetPx)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .onAppear {
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: geo.size.height)
            }
            .onChange(of: geo.size.height) { newValue in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: newValue)
            }
            .onChange(of: geo.size.width) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: geo.size.height)
            }
            .onChange(of: controller.state.script.text) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: geo.size.height)
            }
            .onChange(of: controller.state.overlay.fontSizePx) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: geo.size.height)
            }
            .onChange(of: controller.state.overlay.lineHeight) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: geo.size.height)
            }
            .onChange(of: controller.state.overlay.letterSpacingPx) { _ in
                controller.updateScrollBounds(contentHeight: totalContentHeight, viewportHeight: geo.size.height)
            }
        }
    }

    @ViewBuilder
    private func scriptTextView(textColumnWidth: CGFloat) -> some View {
        let baseText = Text(controller.state.script.text.isEmpty ? " " : controller.state.script.text)
            .font(.system(size: controller.state.overlay.fontSizePx, weight: .black, design: .monospaced))
            .lineSpacing((controller.state.overlay.lineHeight - 1) * controller.state.overlay.fontSizePx)
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .frame(width: textColumnWidth, alignment: .center)
            .fixedSize(horizontal: false, vertical: true)

        if #available(iOS 16.0, *) {
            baseText.kerning(controller.state.overlay.letterSpacingPx)
        } else {
            baseText
        }
    }

    private func measuredTextHeight(textColumnWidth: CGFloat) -> CGFloat {
        let text = controller.state.script.text.isEmpty ? " " : controller.state.script.text
        let fontSize = controller.state.overlay.fontSizePx
        let lineSpacing = (controller.state.overlay.lineHeight - 1) * fontSize

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .heavy),
            .paragraphStyle: paragraph,
            .kern: controller.state.overlay.letterSpacingPx
        ]

        let attributed = NSAttributedString(string: text, attributes: attributes)
        let bounds = attributed.boundingRect(
            with: CGSize(width: max(1, textColumnWidth), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        return ceil(bounds.height)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let deltaY = value.translation.height - lastDragY
                lastDragY = value.translation.height

                if deltaY != 0 {
                    controller.scrollScript(deltaPx: Double(-deltaY))
                }
            }
            .onEnded { _ in
                lastDragY = 0
            }
    }
}

private struct OverlayChromeShape: Shape {
    let isDetached: Bool
    let notchTopRadius: CGFloat
    let detachedTopRadius: CGFloat
    let bottomRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        if isDetached {
            DetachedRoundedOverlayShape(
                topRadius: detachedTopRadius,
                bottomRadius: bottomRadius
            ).path(in: rect)
        } else {
            NotchStyledOverlayShape(
                topRadius: notchTopRadius,
                bottomRadius: bottomRadius
            ).path(in: rect)
        }
    }
}

private struct NotchStyledOverlayShape: Shape {
    let topRadius: CGFloat
    let bottomRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let top = max(0, min(topRadius, min(rect.width * 0.32, rect.height * 0.55)))
        let bottom = max(0, min(bottomRadius, min(rect.width * 0.25, rect.height * 0.5)))
        let leftWallX = rect.minX + top
        let rightWallX = rect.maxX - top
        let shoulderY = rect.minY + top

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rightWallX, y: shoulderY),
            control: CGPoint(x: rightWallX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rightWallX, y: rect.maxY - bottom))
        path.addQuadCurve(
            to: CGPoint(x: rightWallX - bottom, y: rect.maxY),
            control: CGPoint(x: rightWallX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: leftWallX + bottom, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: leftWallX, y: rect.maxY - bottom),
            control: CGPoint(x: leftWallX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: leftWallX, y: shoulderY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: leftWallX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

private struct DetachedRoundedOverlayShape: Shape {
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
