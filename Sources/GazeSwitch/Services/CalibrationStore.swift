import Foundation

final class CalibrationStore: Sendable {
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let url = fileURL {
            self.fileURL = url
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            let dir = appSupport.appendingPathComponent("GazeSwitch")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("calibration.json")
        }
    }

    func save(_ data: CalibrationData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let json = try encoder.encode(data)
        try json.write(to: fileURL, options: .atomic)
    }

    func load() throws -> CalibrationData {
        let json = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CalibrationData.self, from: json)
    }

    func delete() throws {
        try FileManager.default.removeItem(at: fileURL)
    }
}
