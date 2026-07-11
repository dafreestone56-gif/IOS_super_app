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

    func testValidateJSONReportsObject() throws {
        let output = try service.validateJSON("{\"a\":1,\"b\":2}")
        XCTAssertTrue(output.contains("2 top-level key"))
    }

    func testJSONKeys() throws {
        let output = try service.jsonKeys("{\"b\":2,\"a\":1}")
        XCTAssertEqual(output, "a\nb")
    }

    func testCSVToJSON() throws {
        let output = try service.csvToJSON("name,value\nbattery,87")
        XCTAssertTrue(output.contains("\"name\" : \"battery\""))
        XCTAssertTrue(output.contains("\"value\" : \"87\""))
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

    func testHexRoundTrip() {
        let encoded = service.run(.hexEncode, input: "Hi")
        let decoded = service.run(.hexDecode, input: encoded)
        XCTAssertEqual(decoded, "Hi")
    }

    func testHMACSHA256KnownValue() {
        let output = service.run(.hmacSHA256, input: "data", pattern: "key")
        XCTAssertEqual(output, "5031fe3d989c6d1537a013fa6e739da23463fdaec3b70137d828e36ace221bd0")
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

    func testColorContrast() {
        let output = service.run(.colorContrast, input: "#000000", pattern: "#FFFFFF")
        XCTAssertTrue(output.contains("21.00:1"))
    }

    func testURLParse() {
        let output = service.run(.urlParse, input: "https://example.com:443/path?a=1")
        XCTAssertTrue(output.contains("Host: example.com"))
        XCTAssertTrue(output.contains("a=1"))
    }

    func testTimestampReturnsCurrentUnixTimeForBlankInput() {
        let output = service.run(.timestamp, input: "")
        XCTAssertNotNil(Int(output))
    }

    func testWidgetDraftDecodesLegacyDraftWithoutAccent() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "name": "Legacy",
          "theme": "System",
          "background": "Blur",
          "cornerRadius": 12,
          "components": [],
          "updatedAt": 0
        }
        """
        let draft = try JSONDecoder().decode(WidgetDraft.self, from: Data(json.utf8))
        XCTAssertEqual(draft.accent, "Blue")
        XCTAssertEqual(draft.name, "Legacy")
    }

    func testHapticSequenceAHAPExportsEveryStep() throws {
        let ahap = HapticPatternPlayer.ahapJSON(steps: [
            HapticStep(delay: 0, intensity: 0.5, sharpness: 0.2),
            HapticStep(delay: 0.15, intensity: 1.0, sharpness: 0.8)
        ])
        let data = try XCTUnwrap(ahap.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let pattern = object?["Pattern"] as? [[String: Any]]
        XCTAssertEqual(pattern?.count, 2)
    }
}
