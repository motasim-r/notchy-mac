import AppKit
import CoreGraphics
import Foundation

protocol DisplayLocatorProtocol {
    func targetScreen() -> NSScreen?
    func menuBarHeight(for screen: NSScreen) -> CGFloat
}

final class DisplayLocator: DisplayLocatorProtocol {
    func targetScreen() -> NSScreen? {
        if let builtIn = NSScreen.screens.first(where: isBuiltInDisplay) {
            return builtIn
        }

        let mousePoint = NSEvent.mouseLocation
        if let hovered = NSScreen.screens.first(where: { NSMouseInRect(mousePoint, $0.frame, false) }) {
            return hovered
        }

        return NSScreen.main ?? NSScreen.screens.first
    }

    func menuBarHeight(for screen: NSScreen) -> CGFloat {
        max(0, screen.frame.maxY - screen.visibleFrame.maxY)
    }

    private func isBuiltInDisplay(_ screen: NSScreen) -> Bool {
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return false
        }

        let displayID = CGDirectDisplayID(screenNumber.uint32Value)
        return CGDisplayIsBuiltin(displayID) != 0
    }
}
