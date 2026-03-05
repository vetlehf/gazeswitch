import AppKit

struct MonitorInfo: Sendable {
    let displayID: CGDirectDisplayID
    let frame: CGRect
    let name: String
    let center: CGPoint  // in CoreGraphics coordinates (top-left origin)

    static func fromNSScreen(_ screen: NSScreen) -> MonitorInfo? {
        guard let id = screen.deviceDescription[
            NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        ] as? CGDirectDisplayID else { return nil }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        let cgCenter = CGPoint(
            x: screen.frame.midX,
            y: primaryHeight - screen.frame.midY
        )

        return MonitorInfo(
            displayID: id,
            frame: screen.frame,
            name: screen.localizedName,
            center: cgCenter
        )
    }

    static func allMonitors() -> [MonitorInfo] {
        NSScreen.screens.compactMap { fromNSScreen($0) }
    }
}
