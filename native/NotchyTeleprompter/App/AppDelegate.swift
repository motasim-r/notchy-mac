import AppKit
import Carbon
import Combine
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let stateStore = FileStateStore()
    private let migrationService = ElectronMigrationService()
    private let displayLocator: DisplayLocatorProtocol = DisplayLocator()

    private lazy var stateController = AppStateController(
        stateStore: stateStore,
        migrationService: migrationService
    )

    private lazy var notchPanelController = NotchPanelController(
        stateController: stateController,
        displayLocator: displayLocator
    )

    private lazy var editorWindowController = EditorWindowController(stateController: stateController)

    private var hotkeyManager: HotkeyManagerProtocol?
    private var stateSubscription: AnyCancellable?
    private var displayPollTimer: Timer?
    private var localKeyMonitor: Any?
    private var localScrollMonitor: Any?
    private var globalScrollMonitor: Any?

    private var statusItem: NSStatusItem?
    private var togglePanelMenuItem: NSMenuItem?
    private var playPauseMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        stateController.openEditorTabHandler = { [weak self] tab in
            self?.editorWindowController.showAndActivate(tab: tab)
        }

        setupStatusItem()
        setupHotkeys()
        setupSpaceKeyHandler()
        setupScrollHandlers()
        setupObservers()

        stateSubscription = stateController.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.syncUI(with: state)
            }

        syncUI(with: stateController.state)

        // Keep editor available for script input from the first launch.
        editorWindowController.showAndActivate()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        stateController.setPanelVisible(true)
        editorWindowController.showAndActivate()
        return true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let toggleTitle = stateController.state.panel.visible ? "Hide Notch UI" : "Show Notch UI"

        let toggleNotch = NSMenuItem(title: toggleTitle, action: #selector(togglePanelVisibilityAction), keyEquivalent: "")
        let openEditor = NSMenuItem(title: "Open Editor", action: #selector(openEditorAction), keyEquivalent: "")
        let playPause = NSMenuItem(
            title: stateController.state.playback.isPlaying ? "Pause" : "Play",
            action: #selector(togglePlaybackAction),
            keyEquivalent: ""
        )
        let quit = NSMenuItem(title: "Quit Notchy", action: #selector(quitAction), keyEquivalent: "")

        toggleNotch.target = self
        openEditor.target = self
        playPause.target = self
        quit.target = self

        menu.addItem(toggleNotch)
        menu.addItem(openEditor)
        menu.addItem(.separator())
        menu.addItem(playPause)
        menu.addItem(.separator())
        menu.addItem(quit)
        return menu
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregister()
        hotkeyManager = nil

        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }

        if let localScrollMonitor {
            NSEvent.removeMonitor(localScrollMonitor)
            self.localScrollMonitor = nil
        }

        if let globalScrollMonitor {
            NSEvent.removeMonitor(globalScrollMonitor)
            self.globalScrollMonitor = nil
        }

        displayPollTimer?.invalidate()
        displayPollTimer = nil

        notchPanelController.teardown()
        editorWindowController.teardown()

        NotificationCenter.default.removeObserver(self)
    }

    @objc private func togglePanelVisibilityAction() {
        stateController.togglePanelVisible()
    }

    @objc private func openEditorAction() {
        editorWindowController.showAndActivate()
    }

    @objc private func togglePlaybackAction() {
        stateController.togglePlayback()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }

    @objc private func handleScreenParametersChanged() {
        syncUI(with: stateController.state)
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        if let button = item.button {
            button.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Notchy Teleprompter")
            button.imagePosition = .imageOnly
            button.toolTip = "Notchy Teleprompter"
        }

        togglePanelMenuItem = NSMenuItem(title: "Hide Notch UI", action: #selector(togglePanelVisibilityAction), keyEquivalent: "")
        playPauseMenuItem = NSMenuItem(title: "Play", action: #selector(togglePlaybackAction), keyEquivalent: "")

        let openEditorItem = NSMenuItem(title: "Open Editor", action: #selector(openEditorAction), keyEquivalent: "")
        let quitItem = NSMenuItem(title: "Quit Notchy", action: #selector(quitAction), keyEquivalent: "q")

        togglePanelMenuItem?.target = self
        playPauseMenuItem?.target = self
        openEditorItem.target = self
        quitItem.target = self

        let menu = NSMenu()
        if let togglePanelMenuItem {
            menu.addItem(togglePanelMenuItem)
        }
        menu.addItem(openEditorItem)
        menu.addItem(.separator())
        if let playPauseMenuItem {
            menu.addItem(playPauseMenuItem)
        }
        menu.addItem(.separator())
        menu.addItem(quitItem)

        item.menu = menu
    }

    private func setupHotkeys() {
        hotkeyManager = CarbonHotkeyManager { [weak self] action in
            guard let self else { return }

            switch action {
            case .togglePlayback:
                self.stateController.togglePlayback()
            case .speedUp:
                self.stateController.adjustSpeed(delta: 2)
            case .speedDown:
                self.stateController.adjustSpeed(delta: -2)
            case .stepLineUp:
                self.stateController.stepScript(direction: .up)
            case .stepLineDown:
                self.stateController.stepScript(direction: .down)
            }
        }

        hotkeyManager?.register()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Fallback active-display tracking when no built-in screen is available.
        displayPollTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.notchPanelController.sync(with: self.stateController.state)
            }
        }
    }

    private func setupSpaceKeyHandler() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else {
                return event
            }

            if self.shouldHandleSpaceToggle(event: event) {
                self.stateController.togglePlayback()
                return nil
            }

            return event
        }
    }

    private func setupScrollHandlers() {
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            self?.handlePanelScroll(event)
            return event
        }

        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handlePanelScroll(event)
            }
        }
    }

    private func shouldHandleSpaceToggle(event: NSEvent) -> Bool {
        guard event.keyCode == UInt16(kVK_Space) else {
            return false
        }

        let disallowedModifiers = event.modifierFlags.intersection([.command, .control, .option, .function])
        guard disallowedModifiers.isEmpty else {
            return false
        }

        if let textView = NSApp.keyWindow?.firstResponder as? NSTextView, textView.isEditable {
            return false
        }

        return true
    }

    private func handlePanelScroll(_ event: NSEvent) {
        guard stateController.state.panel.visible else {
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        guard notchPanelController.containsScreenPoint(mouseLocation) else {
            return
        }

        let rawDeltaY = Double(event.scrollingDeltaY)
        guard rawDeltaY != 0 else {
            return
        }

        let scaledDeltaY: Double
        if event.hasPreciseScrollingDeltas {
            scaledDeltaY = rawDeltaY
        } else {
            scaledDeltaY = rawDeltaY * 16
        }

        // Invert Y so downward scroll advances the script (text moves upward).
        stateController.scrollScript(deltaPx: -scaledDeltaY)
    }

    private func syncUI(with state: TeleprompterState) {
        notchPanelController.sync(with: state)
        editorWindowController.sync(with: state)

        togglePanelMenuItem?.title = state.panel.visible ? "Hide Notch UI" : "Show Notch UI"
        playPauseMenuItem?.title = state.playback.isPlaying ? "Pause" : "Play"
    }
}
