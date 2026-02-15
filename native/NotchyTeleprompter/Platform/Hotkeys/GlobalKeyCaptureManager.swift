import ApplicationServices
import Carbon
import Foundation

enum BareKeyAction {
    case togglePlayback
    case stepUp
    case stepDown
    case halveSpeed
    case doubleSpeed
}

protocol GlobalKeyCaptureManagerProtocol {
    var permissionGranted: Bool { get }
    var onPermissionChanged: ((Bool) -> Void)? { get set }
    @discardableResult
    func refreshPermissionStatus() -> Bool
    @discardableResult
    func requestAccessibilityPermissionIfNeeded() -> Bool
    func setEnabled(_ enabled: Bool, consumeEvents: Bool)
    func stop()
}

final class CGEventTapGlobalKeyCaptureManager: GlobalKeyCaptureManagerProtocol {
    private(set) var permissionGranted: Bool
    var onPermissionChanged: ((Bool) -> Void)?

    private let actionHandler: (BareKeyAction) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRequestedEnabled = false
    private var consumeEvents = true

    init(actionHandler: @escaping (BareKeyAction) -> Void) {
        self.actionHandler = actionHandler
        permissionGranted = AXIsProcessTrusted()
    }

    deinit {
        disableTap()
    }

    @discardableResult
    func refreshPermissionStatus() -> Bool {
        let granted = AXIsProcessTrusted()
        updatePermission(granted)
        reconfigureTapIfNeeded()
        return permissionGranted
    }

    @discardableResult
    func requestAccessibilityPermissionIfNeeded() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(options)
        updatePermission(granted)
        reconfigureTapIfNeeded()
        return granted
    }

    func setEnabled(_ enabled: Bool, consumeEvents: Bool) {
        isRequestedEnabled = enabled
        self.consumeEvents = consumeEvents
        _ = refreshPermissionStatus()
    }

    func stop() {
        isRequestedEnabled = false
        disableTap()
    }

    fileprivate func handleTapEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        guard let action = mapAction(for: event) else {
            return Unmanaged.passUnretained(event)
        }

        DispatchQueue.main.async { [actionHandler] in
            actionHandler(action)
        }

        return consumeEvents ? nil : Unmanaged.passUnretained(event)
    }

    private func reconfigureTapIfNeeded() {
        if isRequestedEnabled && permissionGranted {
            startTapIfNeeded()
        } else {
            disableTap()
        }
    }

    private func startTapIfNeeded() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            return
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let createdTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: globalEventTapCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("[remote-keys] Could not create CGEvent tap. Accessibility permission may be missing.")
            return
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, createdTap, 0) else {
            print("[remote-keys] Could not create run loop source for CGEvent tap.")
            CFMachPortInvalidate(createdTap)
            return
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: createdTap, enable: true)
        eventTap = createdTap
        runLoopSource = source
    }

    private func disableTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
    }

    private func updatePermission(_ granted: Bool) {
        guard granted != permissionGranted else {
            return
        }
        permissionGranted = granted
        onPermissionChanged?(granted)
    }

    private func mapAction(for event: CGEvent) -> BareKeyAction? {
        let disallowedFlags: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskSecondaryFn]
        if !event.flags.intersection(disallowedFlags).isEmpty {
            return nil
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1

        switch keyCode {
        case Int64(kVK_Space):
            return isAutoRepeat ? nil : .togglePlayback
        case Int64(kVK_UpArrow):
            return .stepUp
        case Int64(kVK_DownArrow):
            return .stepDown
        case Int64(kVK_LeftArrow):
            return .halveSpeed
        case Int64(kVK_RightArrow):
            return .doubleSpeed
        default:
            return nil
        }
    }
}

private let globalEventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else {
        return nil
    }

    let manager = Unmanaged<CGEventTapGlobalKeyCaptureManager>.fromOpaque(userInfo).takeUnretainedValue()
    return manager.handleTapEvent(type: type, event: event)
}
