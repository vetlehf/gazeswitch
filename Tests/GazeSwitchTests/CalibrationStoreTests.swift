import XCTest
@testable import GazeSwitch

final class CalibrationStoreTests: XCTestCase {
    private var tempURL: URL!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL)
        super.tearDown()
    }

    func testSaveAndLoad() throws {
        let store = CalibrationStore(fileURL: tempURL)
        let data = CalibrationData(
            monitors: [
                MonitorCalibration(
                    screenID: 42,
                    gazeCenter: GazeSignal(pupilRatio: 0.5, yaw: 0.0),
                    screenCenter: CGPoint(x: 960, y: 540)
                )
            ],
            boundaries: []
        )

        try store.save(data)
        let loaded = try store.load()

        XCTAssertEqual(loaded.monitors.count, 1)
        XCTAssertEqual(loaded.monitors[0].screenID, 42)
    }

    func testLoadMissingFileReturnsNil() {
        let store = CalibrationStore(fileURL: tempURL)
        XCTAssertNil(try? store.load())
    }
}
