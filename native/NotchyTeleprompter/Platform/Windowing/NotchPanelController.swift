import AppKit
import SwiftUI

final class NotchPanelController: NSWindowController {
    private let stateController: AppStateController
    private let displayLocator: DisplayLocatorProtocol
    private let hostingView: NSHostingView<TeleprompterPanelView>

    init(stateController: AppStateController, displayLocator: DisplayLocatorProtocol) {
        self.stateController = stateController
        self.displayLocator = displayLocator

        let rootView = TeleprompterPanelView(controller: stateController)
        hostingView = NSHostingView(rootView: rootView)

        let initialState = stateController.state
        let initialSize = Self.panelSize(for: initialState)
        let panel = NotchPanel(
            contentRect: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.animationBehavior = .none

        panel.contentView = hostingView

        super.init(window: panel)

        applyCaptureSharingState(panel: panel, state: initialState)
        applyPlacement(for: initialState)
        sync(with: initialState)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func sync(with state: TeleprompterState) {
        applyPlacement(for: state)
        if let panel = window {
            applyCaptureSharingState(panel: panel, state: state)
        }

        if state.panel.visible {
            window?.orderFrontRegardless()
        } else {
            window?.orderOut(nil)
        }
    }

    func teardown() {
        window?.orderOut(nil)
        close()
    }

    func containsScreenPoint(_ point: NSPoint) -> Bool {
        guard
            let panel = window,
            panel.isVisible
        else {
            return false
        }

        return panel.frame.contains(point)
    }

    private func applyPlacement(for state: TeleprompterState) {
        guard
            let panel = window,
            let targetScreen = displayLocator.targetScreen()
        else {
            return
        }

        let size = Self.panelSize(for: state)
        let width = size.width
        let height = size.height

        // Zero-gap anchor: panel top edge starts at the physical top edge of the screen.
        let topAnchor = targetScreen.frame.maxY

        let x = targetScreen.frame.midX - (width / 2)
        // Positive vertical position should move the panel downward (further from menu bar).
        let rawY = (topAnchor - height) - CGFloat(state.panel.verticalNudgePx)
        let minY = targetScreen.frame.minY
        let maxY = targetScreen.frame.maxY - height
        let y = min(max(rawY, minY), maxY)

        panel.setFrame(
            NSRect(x: x, y: y, width: width, height: height),
            display: true
        )
    }

    private static func panelSize(for state: TeleprompterState) -> CGSize {
        CGSize(
            width: CGFloat(state.panel.width),
            height: CGFloat(state.panel.height) + NotchPanelLayoutMetrics.timerExtraHeight(showTimer: state.panel.showTimer)
        )
    }

    private func applyCaptureSharingState(panel: NSWindow, state: TeleprompterState) {
        panel.sharingType = state.panel.excludeFromCapture ? .none : .readWrite
    }
}

private final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
