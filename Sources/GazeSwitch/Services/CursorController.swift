import AppKit
import CoreGraphics

enum CursorController {
    static func nsPointToCGPoint(_ nsPoint: NSPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: nsPoint.x, y: primaryScreenHeight - nsPoint.y)
    }

    static func screenCenter(frame: CGRect, primaryScreenHeight: CGFloat) -> CGPoint {
        let nsCenter = NSPoint(x: frame.midX, y: frame.midY)
        return nsPointToCGPoint(nsCenter, primaryScreenHeight: primaryScreenHeight)
    }

    @discardableResult
    static func warpToScreen(_ screen: NSScreen) -> Bool {
        guard hasAccessibilityPermission() else {
            GazeLog.cursor.warning("Warp blocked: no accessibility permission")
            return false
        }
        guard let primaryHeight = NSScreen.screens.first?.frame.height else { return false }
        let center = screenCenter(frame: screen.frame, primaryScreenHeight: primaryHeight)
        GazeLog.cursor.info("Warping to (\(center.x, privacy: .public), \(center.y, privacy: .public))")
        let result = CGWarpMouseCursorPosition(center)
        if result != .success {
            GazeLog.cursor.error("CGWarpMouseCursorPosition failed: \(result.rawValue)")
        }
        return result == .success
    }

    @discardableResult
    static func warp(to cgPoint: CGPoint) -> Bool {
        guard hasAccessibilityPermission() else {
            GazeLog.cursor.warning("Warp blocked: no accessibility permission")
            return false
        }
        return CGWarpMouseCursorPosition(cgPoint) == .success
    }

    static func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func screen(for displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { screen in
            let id = screen.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
            return id == displayID
        }
    }
}
