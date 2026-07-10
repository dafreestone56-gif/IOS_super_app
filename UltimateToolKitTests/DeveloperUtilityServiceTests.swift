import XCTest
@testable import UltimateToolKit

final class DeveloperUtilityServiceTests: XCTestCase {
    private let service = DeveloperUtilityService()

    func testFormatJSONSortsAndPrettyPrints() throws {
        let output = try service.formatJSON("{\"b\":2,\"a\":1}")
        XCTAssertTrue(output.contains("\"a\" : 1"))
        XCTAssertTrue(output.contains("\"b\" : 2"))
    }

    func testMinifyJSONRemovesWhitespace() throws {
        let output = try service.minifyJSON("{\n  \"a\" : 1\n}")
        XCTAssertEqual(output, "{\"a\":1}")
    }

    func testBase64RoundTrip() {
        let encoded = service.run(.base64Encode, input: "Playground")
        let decoded = service.run(.base64Decode, input: encoded)
        XCTAssertEqual(decoded, "Playground")
    }

    func testSHA256KnownValue() {
        let hash = service.run(.sha256, input: "abc")
        XCTAssertEqual(hash, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testRegexMatches() {
        let output = service.run(.regex, input: "BLE NFC BLE", pattern: "BLE")
        XCTAssertTrue(output.contains("Match 1"))
        XCTAssertTrue(output.contains("Match 2"))
    }

    func testRegexRequiresPattern() {
        let output = service.run(.regex, input: "BLE NFC", pattern: "")
        XCTAssertEqual(output, "Enter a regex pattern.")
    }

    func testHexColorToRGB() {
        let output = service.run(.colorHexToRGB, input: "#007AFF")
        XCTAssertTrue(output.contains("RGB(0, 122, 255)"))
    }

    func testTimestampReturnsCurrentUnixTimeForBlankInput() {
        let output = service.run(.timestamp, input: "")
        XCTAssertNotNil(Int(output))
    }
}
