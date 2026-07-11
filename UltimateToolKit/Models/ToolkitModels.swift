import Foundation
import SwiftUI

enum ToolkitModule: String, CaseIterable, Identifiable, Hashable {
    case bluetooth
    case sensors
    case wifi
    case nfc
    case automation
    case widgetStudio
    case camera
    case network
    case audio
    case haptics
    case developerTools
    case shortcuts
    case ai
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bluetooth: return "Bluetooth"
        case .sensors: return "Sensors"
        case .wifi: return "Wi-Fi"
        case .nfc: return "NFC"
        case .automation: return "Automation"
        case .widgetStudio: return "Widget Studio"
        case .camera: return "Camera"
        case .network: return "Network"
        case .audio: return "Audio"
        case .haptics: return "Haptics"
        case .developerTools: return "Developer Tools"
        case .shortcuts: return "Shortcuts"
        case .ai: return "AI Lab"
        case .settings: return "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .bluetooth: return "Scan and inspect BLE"
        case .sensors: return "Live device telemetry"
        case .wifi: return "Current network"
        case .nfc: return "Read and write tags"
        case .automation: return "Rules and triggers"
        case .widgetStudio: return "Design dashboards"
        case .camera: return "Vision and capture"
        case .network: return "Diagnostics and clients"
        case .audio: return "Waveform and speech"
        case .haptics: return "Pattern editor"
        case .developerTools: return "JSON, hashes, regex"
        case .shortcuts: return "AppIntents catalog"
        case .ai: return "Prompt and ML tools"
        case .settings: return "Privacy and data"
        }
    }

    var statusText: String {
        switch self {
        case .bluetooth: return "Scan"
        case .sensors: return "Live"
        case .wifi: return "Network"
        case .nfc: return "Reader"
        case .automation: return "Rules"
        case .widgetStudio: return "Builder"
        case .camera: return "Capture"
        case .network: return "Tools"
        case .audio: return "Monitor"
        case .haptics: return "Editor"
        case .developerTools: return "Offline"
        case .shortcuts: return "Actions"
        case .ai: return "Opt-in"
        case .settings: return "Local"
        }
    }

    var symbol: String {
        switch self {
        case .bluetooth: return "bolt.horizontal.circle.fill"
        case .sensors: return "waveform.path.ecg"
        case .wifi: return "wifi"
        case .nfc: return "wave.3.right.circle.fill"
        case .automation: return "gearshape.2.fill"
        case .widgetStudio: return "square.grid.2x2.fill"
        case .camera: return "camera.fill"
        case .network: return "network"
        case .audio: return "waveform"
        case .haptics: return "circle.hexagongrid.circle"
        case .developerTools: return "terminal.fill"
        case .shortcuts: return "point.3.connected.trianglepath.dotted"
        case .ai: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }

    var tint: Color {
        switch self {
        case .bluetooth, .wifi, .network, .shortcuts: return Color.blue
        case .sensors: return Color.green
        case .nfc: return Color.orange
        case .automation, .haptics: return Color.purple
        case .widgetStudio: return Color.pink
        case .camera: return Color.cyan
        case .audio: return Color.indigo
        case .developerTools: return Color.gray
        case .ai: return Color.mint
        case .settings: return Color.secondary
        }
    }

    static let favorites: [ToolkitModule] = [
        .bluetooth, .sensors, .wifi, .nfc, .automation, .widgetStudio
    ]

    static let toolList: [ToolkitModule] = [
        .camera, .network, .audio, .haptics, .developerTools, .ai, .settings
    ]
}

struct ToolItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
}

struct SensorMetric: Identifiable {
    var id: String { title }
    let title: String
    let detail: String
    let value: String
    let symbol: String
    let tint: Color
    let trend: [Double]
}

struct SensorLogSample: Identifiable, Codable, Hashable {
    var id = UUID()
    let date: Date
    let sensor: String
    let value: Double
    let detail: String
}

struct BLEDevice: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var rssi: Int
    var advertisement: String
    var lastSeen: Date
    var isConnected: Bool = false
}

struct BLEServiceInfo: Identifiable, Hashable {
    let id: String
    var uuid: String
    var characteristics: [BLECharacteristicInfo]
}

struct BLECharacteristicInfo: Identifiable, Hashable {
    let id: String
    var uuid: String
    var properties: [String]
    var valuePreview: String
}

struct NFCScanResult: Identifiable, Codable, Hashable {
    var id = UUID()
    let date: Date
    let title: String
    let payload: String
    let detail: String
}

struct ToolHistoryItem: Identifiable, Codable, Hashable {
    var id = UUID()
    let date: Date
    let toolName: String
    let inputPreview: String
    let outputPreview: String
}

struct NetworkHistoryItem: Identifiable, Codable, Hashable {
    var id = UUID()
    let date: Date
    let title: String
    let request: String
    let response: String
    let durationMilliseconds: Int
}

struct BonjourServiceInfo: Identifiable, Hashable {
    var id: String { "\(name)-\(type)-\(domain)" }
    let name: String
    let type: String
    let domain: String
    let hostName: String
    let port: Int
}

struct WidgetDraftComponent: Identifiable, Codable, Hashable {
    var id = UUID()
    var kind: String
    var binding: String
    var title: String
}

struct WidgetDraft: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var theme: String
    var background: String
    var accent: String = "Blue"
    var cornerRadius: Double
    var components: [WidgetDraftComponent]
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        theme: String,
        background: String,
        accent: String = "Blue",
        cornerRadius: Double,
        components: [WidgetDraftComponent],
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.theme = theme
        self.background = background
        self.accent = accent
        self.cornerRadius = cornerRadius
        self.components = components
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case theme
        case background
        case accent
        case cornerRadius
        case components
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        theme = try container.decode(String.self, forKey: .theme)
        background = try container.decode(String.self, forKey: .background)
        accent = try container.decodeIfPresent(String.self, forKey: .accent) ?? "Blue"
        cornerRadius = try container.decode(Double.self, forKey: .cornerRadius)
        components = try container.decode([WidgetDraftComponent].self, forKey: .components)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct HapticStep: Identifiable, Codable, Hashable {
    var id = UUID()
    var delay: Double
    var intensity: Double
    var sharpness: Double
}

struct SavedHapticSequence: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var steps: [HapticStep]
    var updatedAt: Date
}

struct AutomationRule: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var trigger: String
    var action: String
    var symbol: String
    var tintKey: String
    var isEnabled: Bool

    var tint: Color {
        switch tintKey {
        case "green": return Color.green
        case "orange": return Color.orange
        case "red": return Color.red
        case "blue": return Color.blue
        case "pink": return Color.pink
        default: return Color.purple
        }
    }
}

struct ConsoleLine: Identifiable, Codable, Hashable {
    enum Direction: String, Codable {
        case inbound = "<"
        case outbound = ">"
        case system = "-"
    }

    var id = UUID()
    let direction: Direction
    let text: String
}

struct LogEntry: Identifiable, Hashable {
    enum Level: String {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
    }

    let id = UUID()
    let date: Date
    let level: Level
    let message: String
}

enum DeveloperToolKind: String, CaseIterable, Identifiable {
    case validateJSON = "Validate JSON"
    case formatJSON = "Format JSON"
    case minifyJSON = "Minify JSON"
    case jsonKeys = "JSON Top-Level Keys"
    case csvToJSON = "CSV to JSON"
    case base64Encode = "Base64 Encode"
    case base64Decode = "Base64 Decode"
    case base64URLEncode = "Base64URL Encode"
    case base64URLDecode = "Base64URL Decode"
    case hexEncode = "Hex Encode"
    case hexDecode = "Hex Decode"
    case sha256 = "SHA-256"
    case sha1 = "SHA-1"
    case md5 = "MD5"
    case hmacSHA256 = "HMAC SHA-256"
    case urlParse = "Parse URL"
    case urlEncode = "URL Encode"
    case urlDecode = "URL Decode"
    case uuid = "Generate UUID"
    case jwtDecode = "Decode JWT"
    case regex = "Regex Matches"
    case colorHexToRGB = "Hex Color to RGB"
    case colorContrast = "Color Contrast"
    case textDiff = "Text Diff"
    case timestamp = "Unix Timestamp"

    var id: String { rawValue }

    var needsAuxiliaryInput: Bool {
        switch self {
        case .regex, .hmacSHA256, .colorContrast, .textDiff:
            return true
        default:
            return false
        }
    }

    var auxiliaryPlaceholder: String {
        switch self {
        case .regex:
            return "Regex pattern"
        case .hmacSHA256:
            return "Secret key"
        case .colorContrast:
            return "Second hex color"
        case .textDiff:
            return "Comparison text"
        default:
            return "Options"
        }
    }
}

enum TerminalMode: String, CaseIterable, Identifiable, Codable {
    case ascii = "ASCII"
    case hex = "HEX"
    case binary = "BIN"

    var id: String { rawValue }
}
