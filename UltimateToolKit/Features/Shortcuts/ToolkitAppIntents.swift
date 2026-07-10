import AppIntents
import Foundation
import UIKit

@available(iOS 16.0, *)
struct GetBatteryLevelIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Battery Level"
    static var description = IntentDescription("Returns the current device battery level as a decimal from 0 to 1.")

    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let level = await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            return UIDevice.current.batteryLevel
        }
        return .result(value: Double(level))
    }
}

@available(iOS 16.0, *)
struct FormatJSONIntent: AppIntent {
    static var title: LocalizedStringResource = "Format JSON"
    static var description = IntentDescription("Pretty-prints a JSON string locally on device.")

    @Parameter(title: "JSON")
    var json: String

    init() {
        json = "{}"
    }

    init(json: String) {
        self.json = json
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let service = DeveloperUtilityService()
        return .result(value: service.run(.formatJSON, input: json))
    }
}

@available(iOS 16.0, *)
struct ToolkitShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: GetBatteryLevelIntent(),
                phrases: ["Get battery level in \(.applicationName)"],
                shortTitle: "Battery",
                systemImageName: "battery.100"
            ),
            AppShortcut(
                intent: FormatJSONIntent(),
                phrases: ["Format JSON in \(.applicationName)"],
                shortTitle: "Format JSON",
                systemImageName: "curlybraces"
            )
        ]
    }
}
