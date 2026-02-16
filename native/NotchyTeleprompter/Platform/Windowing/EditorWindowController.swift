import AppKit
import SwiftUI

final class EditorWindowController: NSWindowController, NSWindowDelegate {
    private let stateController: AppStateController
    private let editorSessionState = EditorSessionState()
    private let hostingController: NSHostingController<EditorView>

    private var isApplyingStateFrame = false

    init(stateController: AppStateController) {
        self.stateController = stateController
        hostingController = NSHostingController(
            rootView: EditorView(
                controller: stateController,
                sessionState: editorSessionState
            )
        )

        let state = stateController.state
        let startRect = NSRect(
            x: state.editor.originX ?? 200,
            y: state.editor.originY ?? 180,
            width: state.editor.width,
            height: state.editor.height
        )

        let window = NSWindow(
            contentRect: startRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Notchy Teleprompter"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unifiedCompact
        window.isMovableByWindowBackground = true
        window.styleMask.insert(.fullSizeContentView)
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: TeleprompterState.limits.editorWidthMin, height: TeleprompterState.limits.editorHeightMin)
        window.contentViewController = hostingController
        window.delegate = nil

        super.init(window: window)

        window.delegate = self
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func sync(with state: TeleprompterState) {
        guard let window else { return }

        let targetSize = NSSize(width: state.editor.width, height: state.editor.height)
        let currentFrame = window.frame

        var targetOrigin = currentFrame.origin
        if let x = state.editor.originX, let y = state.editor.originY {
            targetOrigin = NSPoint(x: x, y: y)
        }

        if abs(currentFrame.size.width - targetSize.width) > 0.5 ||
            abs(currentFrame.size.height - targetSize.height) > 0.5 ||
            abs(currentFrame.origin.x - targetOrigin.x) > 0.5 ||
            abs(currentFrame.origin.y - targetOrigin.y) > 0.5 {
            isApplyingStateFrame = true
            window.setFrame(NSRect(origin: targetOrigin, size: targetSize), display: true)
            isApplyingStateFrame = false
        }
    }

    func showAndActivate(tab: EditorTab? = nil) {
        guard let window else { return }
        if let tab {
            editorSessionState.selectedTab = tab
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func teardown() {
        window?.orderOut(nil)
        close()
    }

    func windowDidMove(_ notification: Notification) {
        persistWindowFrameIfNeeded()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        persistWindowFrameIfNeeded()
    }

    func windowDidResize(_ notification: Notification) {
        persistWindowFrameIfNeeded()
    }

    private func persistWindowFrameIfNeeded() {
        guard
            !isApplyingStateFrame,
            let window
        else {
            return
        }

        let frame = window.frame
        stateController.setEditorFrame(
            width: frame.width,
            height: frame.height,
            originX: frame.origin.x,
            originY: frame.origin.y
        )
    }
}
