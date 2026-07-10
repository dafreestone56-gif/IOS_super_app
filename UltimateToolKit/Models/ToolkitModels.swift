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
        case .bluetooth: "Bluetooth"
        case .sensors: "Sensors"
        case .wifi: "Wi-Fi"
        case .nfc: "NFC"
        case .automation: "Automation"
        case .widgetStudio: "Widget Studio"
        case .camera: "Camera"
        case .network: "Network"
        case .audio: "Audio"
        case .haptics: "Haptics"
        case .developerTools: "Developer Tools"
        case .shortcuts: "Shortcuts"
        case .ai: "AI Lab"
        case .settings: "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .bluetooth: "Scan and inspect BLE"
        case .sensors: "Live device telemetry"
        case .wifi: "Current network"
        case .nfc: "Read and write tags"
        case .automation: "Rules and triggers"
        case .widgetStudio: "Design dashboards"
        case .camera: "Vision and capture"
        case .network: "Diagnostics and clients"
        case .audio: "Waveform and speech"
        case .haptics: "Pattern editor"
        case .developerTools: "JSON, hashes, regex"
        case .shortcuts: "AppIntents catalog"
        case .ai: "Prompt and ML tools"
        case .settings: "Privacy and data"
        }
    }

    var statusText: String {
        switch self {
        case .bluetooth: "Scan"
        case .sensors: "Live"
        case .wifi: "Network"
        case .nfc: "Reader"
        case .automation: "Rules"
        case .widgetStudio: "Builder"
        case .camera: "Capture"
        case .network: "Tools"
        case .audio: "Monitor"
        case .haptics: "Editor"
        case .developerTools: "Offline"
        case .shortcuts: "Actions"
        case .ai: "Opt-in"
        case .settings: "Local"
        }
    }

    var symbol: String {
        switch self {
        case .bluetooth: "bolt.horizontal.circle.fill"
        case .sensors: "waveform.path.ecg"
        case .wifi: "wifi"
        case .nfc: "wave.3.right.circle.fill"
        case .automation: "gearshape.2.fill"
        case .widgetStudio: "square.grid.2x2.fill"
        case .camera: "camera.fill"
        case .network: "network"
        case .audio: "waveform"
        case .haptics: "circle.hexagongrid.circle"
        case .developerTools: "terminal.fill"
        case .shortcuts: "point.3.connected.trianglepath.dotted"
        case .ai: "sparkles"
        case .settings: "gearshape.fill"
        }
    }

    var tint: Color {
        switch self {
        case .bluetooth, .wifi, .network, .shortcuts: .blue
        case .sensors: .green
        case .nfc: .orange
        case .automation, .haptics: .purple
        case .widgetStudio: .pink
        case .camera: .cyan
        case .audio: .indigo
        case .developerTools: .gray
        case .ai: .mint
        case .settings: .secondary
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
    let id = UUID()
    let title: String
    let detail: String
    let value: String
    let symbol: String
    let tint: Color
    let trend: [Double]
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
        case "green": .green
        case "orange": .orange
        case "red": .red
        case "blue": .blue
        case "pink": .pink
        default: .purple
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
    case formatJSON = "Format JSON"
    case minifyJSON = "Minify JSON"
    case base64Encode = "Base64 Encode"
    case base64Decode = "Base64 Decode"
    case sha256 = "SHA-256"
    case urlEncode = "URL Encode"
    case urlDecode = "URL Decode"
    case uuid = "Generate UUID"
    case jwtDecode = "Decode JWT"
    case regex = "Regex Matches"
    case colorHexToRGB = "Hex Color to RGB"
    case timestamp = "Unix Timestamp"
}

enum TerminalMode: String, CaseIterable, Identifiable, Codable {
    case ascii = "ASCII"
    case hex = "HEX"
    case binary = "BIN"

    var id: String { rawValue }
}
