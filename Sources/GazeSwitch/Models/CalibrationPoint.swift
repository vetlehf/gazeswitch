import Foundation

enum CalibrationPosition: String, Codable, Sendable, CaseIterable {
    case center
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var label: String {
        switch self {
        case .center: return "center"
        case .topLeft: return "top-left corner"
        case .topRight: return "top-right corner"
        case .bottomLeft: return "bottom-left corner"
        case .bottomRight: return "bottom-right corner"
        }
    }
}

struct CalibrationPoint: Codable, Equatable, Sendable {
    let position: CalibrationPosition
    let signal: GazeSignal
}
