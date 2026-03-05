import os

enum GazeLog {
    static let camera = Logger(subsystem: "com.gazeswitch", category: "camera")
    static let gaze = Logger(subsystem: "com.gazeswitch", category: "gaze")
    static let resolver = Logger(subsystem: "com.gazeswitch", category: "resolver")
    static let cursor = Logger(subsystem: "com.gazeswitch", category: "cursor")
    static let dwell = Logger(subsystem: "com.gazeswitch", category: "dwell")
    static let engine = Logger(subsystem: "com.gazeswitch", category: "engine")
}
