import Carbon
import Foundation

enum HotkeyAction {
    case togglePlayback
    case speedUp
    case speedDown
    case stepLineUp
    case stepLineDown
}

protocol HotkeyManagerProtocol {
    func register()
    func unregister()
}

final class CarbonHotkeyManager: HotkeyManagerProtocol {
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var actionByIdentifier: [UInt32: HotkeyAction] = [:]
    private var nextIdentifier: UInt32 = 1

    private let actionHandler: (HotkeyAction) -> Void

    init(actionHandler: @escaping (HotkeyAction) -> Void) {
        self.actionHandler = actionHandler
    }

    func register() {
        unregister()
        installEventHandler()

        // Command+Shift combos
        register(action: .togglePlayback, keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey | shiftKey))
        register(action: .speedDown, keyCode: UInt32(kVK_LeftArrow), modifiers: UInt32(cmdKey | shiftKey))
        register(action: .speedUp, keyCode: UInt32(kVK_RightArrow), modifiers: UInt32(cmdKey | shiftKey))
        register(action: .stepLineUp, keyCode: UInt32(kVK_UpArrow), modifiers: UInt32(cmdKey | shiftKey))
        register(action: .stepLineDown, keyCode: UInt32(kVK_DownArrow), modifiers: UInt32(cmdKey | shiftKey))
    }

    func unregister() {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
        actionByIdentifier.removeAll()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, eventRef, userData in
            guard
                let eventRef,
                let userData
            else {
                return noErr
            }

            let manager = Unmanaged<CarbonHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotkeyEvent(eventRef)
            return noErr
        }

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        if status != noErr {
            print("[hotkeys] Failed to install event handler (\(status))")
        }
    }

    private func register(action: HotkeyAction, keyCode: UInt32, modifiers: UInt32) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4E545052), id: nextIdentifier) // NTPR
        nextIdentifier += 1

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            print("[hotkeys] Failed to register keyCode=\(keyCode) modifiers=\(modifiers) status=\(status)")
            return
        }

        hotKeyRefs.append(hotKeyRef)
        actionByIdentifier[hotKeyID.id] = action
    }

    private func handleHotkeyEvent(_ eventRef: EventRef) {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr, let action = actionByIdentifier[hotKeyID.id] else {
            return
        }

        DispatchQueue.main.async { [actionHandler] in
            actionHandler(action)
        }
    }
}
