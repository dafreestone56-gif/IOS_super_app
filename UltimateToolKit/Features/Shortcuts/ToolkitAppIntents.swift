import AppIntents
import Foundation
import UIKit

@available(iOS 16.0, *)
struct LoggedSensorOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let samples = AppPersistence.load([SensorLogSample].self, key: "sensor.loggedSamples", fallback: [])
        let names = Array(Set(samples.map(\.sensor))).sorted()
        return names.isEmpty ? ["Accelerometer", "Gyroscope", "Magnetometer", "Barometer", "Location"] : names
    }
}

@available(iOS 16.0, *)
struct HapticSequenceOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let sequences = AppPersistence.load([SavedHapticSequence].self, key: "haptic.sequences", fallback: [])
        let names = sequences.map(\.name)
        return names.isEmpty ? ["Default success haptic"] : names
    }
}

@available(iOS 16.0, *)
struct WidgetDraftOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let drafts = AppPersistence.load([WidgetDraft].self, key: "widget.drafts", fallback: [])
        let names = drafts.map(\.name)
        return names.isEmpty ? ["Latest Widget Draft"] : names
    }
}

@available(iOS 16.0, *)
struct AutomationRuleOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let rules = AppPersistence.load([AutomationRule].self, key: "automation.rules", fallback: [])
        let names = rules.map(\.title)
        return names.isEmpty ? ["Battery Pulse", "Network Drop Notice", "NFC Capture Log"] : names
    }
}

@available(iOS 16.0, *)
struct ToolkitModuleOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        ToolkitModule.allCases.map(\.title)
    }
}

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
struct GetDeviceSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Device Summary"
    static var description = IntentDescription("Returns model, system version, battery, thermal state, screen scale, and brightness.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let summary = await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let battery = UIDevice.current.batteryLevel >= 0 ? "\(Int(UIDevice.current.batteryLevel * 100))%" : "Unavailable"
            let thermal = ProcessInfo.processInfo.thermalState.shortDescription
            return """
            Device: \(UIDevice.current.model)
            System: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
            Battery: \(battery)
            Thermal: \(thermal)
            Brightness: \(Int(UIScreen.main.brightness * 100))%
            Scale: \(UIScreen.main.scale)x
            """
        }
        return .result(value: summary)
    }
}

@available(iOS 16.0, *)
struct GetThermalStateIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Thermal State"
    static var description = IntentDescription("Returns the current ProcessInfo thermal state.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: ProcessInfo.processInfo.thermalState.shortDescription)
    }
}

@available(iOS 16.0, *)
struct GetScreenBrightnessIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Screen Brightness"
    static var description = IntentDescription("Returns screen brightness from 0 to 1.")

    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let brightness = await MainActor.run { Double(UIScreen.main.brightness) }
        return .result(value: brightness)
    }
}

@available(iOS 16.0, *)
struct ValidateJSONIntent: AppIntent {
    static var title: LocalizedStringResource = "Validate JSON"
    static var description = IntentDescription("Validates JSON locally and returns a summary.")

    @Parameter(title: "JSON")
    var json: String

    init() { json = "{}" }
    init(json: String) { self.json = json }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.validateJSON, input: json))
    }
}

@available(iOS 16.0, *)
struct FormatJSONIntent: AppIntent {
    static var title: LocalizedStringResource = "Format JSON"
    static var description = IntentDescription("Pretty-prints a JSON string locally on device.")

    @Parameter(title: "JSON")
    var json: String

    init() { json = "{}" }
    init(json: String) { self.json = json }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.formatJSON, input: json))
    }
}

@available(iOS 16.0, *)
struct MinifyJSONIntent: AppIntent {
    static var title: LocalizedStringResource = "Minify JSON"
    static var description = IntentDescription("Minifies JSON locally on device.")

    @Parameter(title: "JSON")
    var json: String

    init() { json = "{}" }
    init(json: String) { self.json = json }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.minifyJSON, input: json))
    }
}

@available(iOS 16.0, *)
struct CSVToJSONIntent: AppIntent {
    static var title: LocalizedStringResource = "Convert CSV to JSON"
    static var description = IntentDescription("Converts CSV text with a header row into JSON.")

    @Parameter(title: "CSV")
    var csv: String

    init() { csv = "" }
    init(csv: String) { self.csv = csv }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.csvToJSON, input: csv))
    }
}

@available(iOS 16.0, *)
struct Base64EncodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Base64 Encode"
    static var description = IntentDescription("Encodes text as Base64.")

    @Parameter(title: "Text")
    var text: String

    init() { text = "" }
    init(text: String) { self.text = text }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.base64Encode, input: text))
    }
}

@available(iOS 16.0, *)
struct Base64DecodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Base64 Decode"
    static var description = IntentDescription("Decodes Base64 text.")

    @Parameter(title: "Base64")
    var base64: String

    init() { base64 = "" }
    init(base64: String) { self.base64 = base64 }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.base64Decode, input: base64))
    }
}

@available(iOS 16.0, *)
struct HexEncodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Hex Encode"
    static var description = IntentDescription("Encodes text as hexadecimal bytes.")

    @Parameter(title: "Text")
    var text: String

    init() { text = "" }
    init(text: String) { self.text = text }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.hexEncode, input: text))
    }
}

@available(iOS 16.0, *)
struct SHA256HashIntent: AppIntent {
    static var title: LocalizedStringResource = "SHA-256 Hash"
    static var description = IntentDescription("Hashes text with SHA-256.")

    @Parameter(title: "Text")
    var text: String

    init() { text = "" }
    init(text: String) { self.text = text }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.sha256, input: text))
    }
}

@available(iOS 16.0, *)
struct HMACSHA256Intent: AppIntent {
    static var title: LocalizedStringResource = "HMAC SHA-256"
    static var description = IntentDescription("Signs text with an HMAC SHA-256 key.")

    @Parameter(title: "Text")
    var text: String

    @Parameter(title: "Secret")
    var secret: String

    init() {
        text = ""
        secret = ""
    }

    init(text: String, secret: String) {
        self.text = text
        self.secret = secret
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.hmacSHA256, input: text, pattern: secret))
    }
}

@available(iOS 16.0, *)
struct GenerateUUIDIntent: AppIntent {
    static var title: LocalizedStringResource = "Generate UUID"
    static var description = IntentDescription("Generates a UUID v4 string.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.uuid, input: ""))
    }
}

@available(iOS 16.0, *)
struct DecodeJWTIntent: AppIntent {
    static var title: LocalizedStringResource = "Decode JWT"
    static var description = IntentDescription("Decodes the header and payload of a JWT without validating its signature.")

    @Parameter(title: "JWT")
    var token: String

    init() { token = "" }
    init(token: String) { self.token = token }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.jwtDecode, input: token))
    }
}

@available(iOS 16.0, *)
struct RegexMatchesIntent: AppIntent {
    static var title: LocalizedStringResource = "Regex Matches"
    static var description = IntentDescription("Returns regular expression matches for text.")

    @Parameter(title: "Text")
    var text: String

    @Parameter(title: "Pattern")
    var pattern: String

    init() {
        text = ""
        pattern = ""
    }

    init(text: String, pattern: String) {
        self.text = text
        self.pattern = pattern
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.regex, input: text, pattern: pattern))
    }
}

@available(iOS 16.0, *)
struct ParseURLIntent: AppIntent {
    static var title: LocalizedStringResource = "Parse URL"
    static var description = IntentDescription("Breaks a URL into scheme, host, path, port, and query items.")

    @Parameter(title: "URL")
    var url: String

    init() { url = "" }
    init(url: String) { self.url = url }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.urlParse, input: url))
    }
}

@available(iOS 16.0, *)
struct ColorContrastIntent: AppIntent {
    static var title: LocalizedStringResource = "Color Contrast"
    static var description = IntentDescription("Calculates WCAG contrast between two hex colors.")

    @Parameter(title: "First Hex Color")
    var first: String

    @Parameter(title: "Second Hex Color")
    var second: String

    init() {
        first = "#000000"
        second = "#FFFFFF"
    }

    init(first: String, second: String) {
        self.first = first
        self.second = second
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: DeveloperUtilityService().run(.colorContrast, input: first, pattern: second))
    }
}

@available(iOS 16.0, *)
struct HTTPRequestIntent: AppIntent {
    static var title: LocalizedStringResource = "Run HTTP Request"
    static var description = IntentDescription("Runs a foreground-safe HTTP request and returns the response body preview.")

    @Parameter(title: "URL")
    var url: String

    @Parameter(title: "Method")
    var method: String

    @Parameter(title: "Headers")
    var headers: String

    @Parameter(title: "Body")
    var body: String

    init() {
        url = "https://"
        method = "GET"
        headers = ""
        body = ""
    }

    init(url: String, method: String = "GET", headers: String = "", body: String = "") {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = await NetworkService().httpRequest(url: url, method: method, headers: headers, body: body)
        return .result(value: String(result.prefix(4000)))
    }
}

@available(iOS 16.0, *)
struct DNSLookupIntent: AppIntent {
    static var title: LocalizedStringResource = "DNS Lookup"
    static var description = IntentDescription("Resolves a host name to IP addresses.")

    @Parameter(title: "Host")
    var host: String

    init() { host = "" }
    init(host: String) { self.host = host }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: await NetworkService().dnsLookup(host: host))
    }
}

@available(iOS 16.0, *)
struct TCPProbeIntent: AppIntent {
    static var title: LocalizedStringResource = "TCP Port Probe"
    static var description = IntentDescription("Checks whether a TCP host and port are reachable.")

    @Parameter(title: "Host")
    var host: String

    @Parameter(title: "Port")
    var port: Int

    init() {
        host = ""
        port = 443
    }

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let safePort = UInt16(exactly: port) else {
            return .result(value: "Port must be between 0 and 65535.")
        }
        return .result(value: await NetworkService().tcpProbe(host: host, port: safePort))
    }
}

@available(iOS 16.0, *)
struct GetNetworkSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Network Summary"
    static var description = IntentDescription("Returns current connectivity, interface, and local IP summary.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let service = NetworkService()
        service.refreshInterfaces()
        let status = service.status
        let interfaces = service.activeInterfaces.joined(separator: ", ")
        let addresses = service.ipAddresses.joined(separator: "\n")
        return .result(value: "Status: \(status)\nInterfaces: \(interfaces.isEmpty ? "Detecting" : interfaces)\nIP Addresses:\n\(addresses.isEmpty ? "Not detected" : addresses)")
    }
}

@available(iOS 16.0, *)
struct GetSensorLogSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sensor Log Summary"
    static var description = IntentDescription("Returns a summary of the last live sensor logging session.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let samples = AppPersistence.load([SensorLogSample].self, key: "sensor.loggedSamples", fallback: [])
        guard !samples.isEmpty else {
            return .result(value: "No sensor logging session has been saved yet.")
        }
        let grouped = Dictionary(grouping: samples, by: \.sensor)
        let lines = grouped.keys.sorted().map { sensor -> String in
            let values = grouped[sensor]?.map(\.value) ?? []
            let minimum = values.min() ?? 0
            let maximum = values.max() ?? 0
            let latest = values.last ?? 0
            return "\(sensor): \(values.count) samples, latest \(String(format: "%.3f", latest)), min \(String(format: "%.3f", minimum)), max \(String(format: "%.3f", maximum))"
        }
        return .result(value: lines.joined(separator: "\n"))
    }
}

@available(iOS 16.0, *)
struct GetLatestSensorSamplesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Latest Sensor Samples"
    static var description = IntentDescription("Returns recent samples for one logged sensor stream.")

    @Parameter(title: "Sensor", optionsProvider: LoggedSensorOptionsProvider())
    var sensor: String

    @Parameter(title: "Count")
    var count: Int

    init() {
        sensor = "Accelerometer"
        count = 10
    }

    init(sensor: String, count: Int = 10) {
        self.sensor = sensor
        self.count = count
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let samples = AppPersistence.load([SensorLogSample].self, key: "sensor.loggedSamples", fallback: [])
        let trimmed = sensor.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = samples.filter { trimmed.isEmpty || $0.sensor.localizedCaseInsensitiveContains(trimmed) }
        guard !matches.isEmpty else {
            return .result(value: "No logged samples matched \(sensor).")
        }
        let formatter = ISO8601DateFormatter()
        let lines = matches.suffix(max(1, min(count, 100))).map { sample in
            "\(formatter.string(from: sample.date)) \(sample.sensor) \(String(format: "%.6f", sample.value))"
        }
        return .result(value: lines.joined(separator: "\n"))
    }
}

@available(iOS 16.0, *)
struct ExportSensorLogCSVIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Sensor Log CSV"
    static var description = IntentDescription("Returns the last live sensor logging session as CSV text.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let samples = AppPersistence.load([SensorLogSample].self, key: "sensor.loggedSamples", fallback: [])
        guard !samples.isEmpty else {
            return .result(value: "date,sensor,value,detail")
        }
        var rows = ["date,sensor,value,detail"]
        let formatter = ISO8601DateFormatter()
        for sample in samples {
            let detail = sample.detail.replacingOccurrences(of: "\"", with: "\"\"")
            rows.append("\"\(formatter.string(from: sample.date))\",\"\(sample.sensor)\",\"\(String(format: "%.6f", sample.value))\",\"\(detail)\"")
        }
        return .result(value: rows.joined(separator: "\n"))
    }
}

@available(iOS 16.0, *)
struct GetLastNFCTagIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Last NFC Tag"
    static var description = IntentDescription("Returns the last stored NFC scan or write result from this app.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let history = AppPersistence.load([NFCScanResult].self, key: "nfc.history", fallback: [])
        guard let item = history.first else {
            return .result(value: "No NFC history saved yet.")
        }
        return .result(value: "\(item.title)\n\(item.detail)\n\(item.payload)")
    }
}

@available(iOS 16.0, *)
struct GetNFCReaderStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get NFC Reader Status"
    static var description = IntentDescription("Returns CoreNFC availability diagnostics for the current signed build.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: NFCService.currentAvailabilityDetail())
    }
}

@available(iOS 16.0, *)
struct PlayHapticIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Haptic"
    static var description = IntentDescription("Plays a simple notification haptic.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            HapticPatternPlayer.shared.play(intensity: 0.75, sharpness: 0.45)
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
        return .result(value: "Haptic played.")
    }
}

@available(iOS 16.0, *)
struct ListHapticSequencesIntent: AppIntent {
    static var title: LocalizedStringResource = "List Haptic Sequences"
    static var description = IntentDescription("Returns saved haptic sequence names.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let sequences = AppPersistence.load([SavedHapticSequence].self, key: "haptic.sequences", fallback: [])
        guard !sequences.isEmpty else {
            return .result(value: "No haptic sequences saved yet.")
        }
        return .result(value: sequences.map { "\($0.name) (\($0.steps.count) steps)" }.joined(separator: "\n"))
    }
}

@available(iOS 16.0, *)
struct PlaySavedHapticSequenceIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Saved Haptic Sequence"
    static var description = IntentDescription("Plays a saved haptic sequence by name.")

    @Parameter(title: "Sequence Name", optionsProvider: HapticSequenceOptionsProvider())
    var sequenceName: String

    init() { sequenceName = "" }
    init(sequenceName: String) { self.sequenceName = sequenceName }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let sequences = AppPersistence.load([SavedHapticSequence].self, key: "haptic.sequences", fallback: [])
        if sequenceName == "Default success haptic" {
            await MainActor.run {
                HapticPatternPlayer.shared.play(intensity: 0.75, sharpness: 0.45)
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
            }
            return .result(value: "Played default success haptic.")
        }
        guard let sequence = sequences.first(where: { $0.name.localizedCaseInsensitiveContains(sequenceName) }) ?? sequences.first else {
            return .result(value: "No haptic sequences saved yet.")
        }
        await MainActor.run {
            HapticPatternPlayer.shared.play(sequence: sequence)
        }
        return .result(value: "Played haptic sequence: \(sequence.name)")
    }
}

@available(iOS 16.0, *)
struct ExportHapticSequenceAHAPIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Haptic AHAP"
    static var description = IntentDescription("Returns AHAP JSON for a saved haptic sequence.")

    @Parameter(title: "Sequence Name", optionsProvider: HapticSequenceOptionsProvider())
    var sequenceName: String

    init() { sequenceName = "" }
    init(sequenceName: String) { self.sequenceName = sequenceName }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let sequences = AppPersistence.load([SavedHapticSequence].self, key: "haptic.sequences", fallback: [])
        guard let sequence = sequences.first(where: { $0.name.localizedCaseInsensitiveContains(sequenceName) }) ?? sequences.first else {
            return .result(value: "{}")
        }
        return .result(value: HapticPatternPlayer.ahapJSON(steps: sequence.steps))
    }
}

@available(iOS 16.0, *)
struct ListWidgetDraftsIntent: AppIntent {
    static var title: LocalizedStringResource = "List Widget Drafts"
    static var description = IntentDescription("Returns saved Widget Studio draft names.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let drafts = AppPersistence.load([WidgetDraft].self, key: "widget.drafts", fallback: [])
        guard !drafts.isEmpty else {
            return .result(value: "No widget drafts saved yet.")
        }
        return .result(value: drafts.map { "\($0.name): \($0.components.count) components, \($0.theme), \($0.background)" }.joined(separator: "\n"))
    }
}

@available(iOS 16.0, *)
struct GetWidgetDraftIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Widget Draft"
    static var description = IntentDescription("Returns JSON for a saved Widget Studio draft.")

    @Parameter(title: "Draft Name", optionsProvider: WidgetDraftOptionsProvider())
    var draftName: String

    init() { draftName = "" }
    init(draftName: String) { self.draftName = draftName }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let drafts = AppPersistence.load([WidgetDraft].self, key: "widget.drafts", fallback: [])
        guard let draft = drafts.first(where: { $0.name.localizedCaseInsensitiveContains(draftName) }) ?? drafts.first,
              let data = try? JSONEncoder().encode(draft),
              let json = String(data: data, encoding: .utf8) else {
            return .result(value: "{}")
        }
        return .result(value: json)
    }
}

@available(iOS 16.0, *)
struct RunAutomationRuleIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Automation Rule"
    static var description = IntentDescription("Runs a saved local automation rule by name and returns the action line.")

    @Parameter(title: "Rule Name", optionsProvider: AutomationRuleOptionsProvider())
    var ruleName: String

    init() { ruleName = "" }
    init(ruleName: String) { self.ruleName = ruleName }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let rules = AppPersistence.load([AutomationRule].self, key: "automation.rules", fallback: [])
        guard let rule = rules.first(where: { $0.title.localizedCaseInsensitiveContains(ruleName) }) ?? rules.first else {
            return .result(value: "No automation rules saved yet.")
        }
        guard rule.isEnabled else {
            return .result(value: "Automation rule is disabled: \(rule.title)")
        }
        let line = "\(Date().formatted(date: .abbreviated, time: .standard)): \(rule.title) -> \(rule.action)"
        var log = AppPersistence.load([String].self, key: "automation.executionLog", fallback: [])
        log.insert(line, at: 0)
        AppPersistence.save(Array(log.prefix(80)), key: "automation.executionLog")
        return .result(value: line)
    }
}

@available(iOS 16.0, *)
struct CopyTextToClipboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Text to Clipboard"
    static var description = IntentDescription("Copies text to the iOS clipboard.")

    @Parameter(title: "Text")
    var text: String

    init() { text = "" }
    init(text: String) { self.text = text }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            UIPasteboard.general.string = text
        }
        return .result(value: "Copied \(text.count) character(s).")
    }
}

@available(iOS 16.0, *)
struct OpenToolkitIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Toolkit"
    static var description = IntentDescription("Opens the app so you can continue in a hardware-gated module.")
    static var openAppWhenRun = true

    @Parameter(title: "Module", optionsProvider: ToolkitModuleOptionsProvider())
    var module: String

    init() { module = "Home" }
    init(module: String) { self.module = module }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: "Opened Toolkit module request: \(module)")
    }
}

@available(iOS 16.0, *)
struct ToolkitShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Apple allows at most 10 visible App Shortcuts per app. Keep the rest as searchable AppIntents.
        AppShortcut(
            intent: GetDeviceSummaryIntent(),
            phrases: ["Get device summary in \(.applicationName)"],
            shortTitle: "Device Summary",
            systemImageName: "iphone.gen3"
        )
        AppShortcut(
            intent: GetSensorLogSummaryIntent(),
            phrases: ["Get sensor log summary in \(.applicationName)"],
            shortTitle: "Sensor Log",
            systemImageName: "waveform.path.ecg"
        )
        AppShortcut(
            intent: ExportSensorLogCSVIntent(),
            phrases: ["Export sensor log in \(.applicationName)"],
            shortTitle: "Sensor CSV",
            systemImageName: "tablecells"
        )
        AppShortcut(
            intent: FormatJSONIntent(),
            phrases: ["Format JSON in \(.applicationName)"],
            shortTitle: "Format JSON",
            systemImageName: "curlybraces"
        )
        AppShortcut(
            intent: HTTPRequestIntent(),
            phrases: ["Run HTTP request in \(.applicationName)"],
            shortTitle: "HTTP",
            systemImageName: "network"
        )
        AppShortcut(
            intent: TCPProbeIntent(),
            phrases: ["Probe TCP port in \(.applicationName)"],
            shortTitle: "TCP Probe",
            systemImageName: "rectangle.connected.to.line.below"
        )
        AppShortcut(
            intent: GetNFCReaderStatusIntent(),
            phrases: ["Check NFC reader in \(.applicationName)"],
            shortTitle: "NFC Status",
            systemImageName: "checklist.checked"
        )
        AppShortcut(
            intent: PlaySavedHapticSequenceIntent(),
            phrases: ["Play saved haptic in \(.applicationName)"],
            shortTitle: "Saved Haptic",
            systemImageName: "waveform.path.badge.plus"
        )
        AppShortcut(
            intent: ListWidgetDraftsIntent(),
            phrases: ["List widget drafts in \(.applicationName)"],
            shortTitle: "Widgets",
            systemImageName: "square.grid.2x2"
        )
        AppShortcut(
            intent: RunAutomationRuleIntent(),
            phrases: ["Run automation rule in \(.applicationName)"],
            shortTitle: "Run Rule",
            systemImageName: "gearshape.2"
        )
    }
}

extension ProcessInfo.ThermalState {
    var shortDescription: String {
        switch self {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
