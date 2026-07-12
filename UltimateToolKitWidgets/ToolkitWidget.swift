import AppIntents
import Foundation
import SwiftUI
import WidgetKit

enum ToolkitWidgetDisplay: String, AppEnum, CaseIterable {
    case system
    case sensors
    case network
    case shortcuts

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget Display")

    static var caseDisplayRepresentations: [ToolkitWidgetDisplay: DisplayRepresentation] = [
        .system: DisplayRepresentation(title: "System"),
        .sensors: DisplayRepresentation(title: "Sensors"),
        .network: DisplayRepresentation(title: "Network"),
        .shortcuts: DisplayRepresentation(title: "Shortcuts")
    ]
}

struct ToolkitWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Toolkit Widget"
    static var description = IntentDescription("Choose the dashboard style shown by the widget.")

    @Parameter(title: "Display")
    var display: ToolkitWidgetDisplay?

    init() {
        display = .system
    }

    var resolvedDisplay: ToolkitWidgetDisplay {
        return display ?? .system
    }
}

struct ToolkitWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ToolkitWidgetConfigurationIntent
    let draft: SharedWidgetDraft?
}

struct ToolkitWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ToolkitWidgetEntry {
        ToolkitWidgetEntry(date: Date(), configuration: ToolkitWidgetConfigurationIntent(), draft: nil)
    }

    func snapshot(for configuration: ToolkitWidgetConfigurationIntent, in context: Context) async -> ToolkitWidgetEntry {
        ToolkitWidgetEntry(date: Date(), configuration: configuration, draft: loadDraft())
    }

    func timeline(for configuration: ToolkitWidgetConfigurationIntent, in context: Context) async -> Timeline<ToolkitWidgetEntry> {
        let entry = ToolkitWidgetEntry(date: Date(), configuration: configuration, draft: loadDraft())
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
    }

    private func loadDraft() -> SharedWidgetDraft? {
        let sharedData = UserDefaults(suiteName: "group.com.personal.playgroundtoolkit")?.data(forKey: "widget.latestDraft")
        let fallbackData = UserDefaults.standard.data(forKey: "widget.latestDraft")
        guard let data = sharedData ?? fallbackData else {
            return nil
        }
        return try? JSONDecoder().decode(SharedWidgetDraft.self, from: data)
    }
}

struct ToolkitWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ToolkitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 10) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            Text(primary)
                .font(family == .systemSmall ? .title3.weight(.semibold) : .title2.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            if let draft = entry.draft, entry.configuration.resolvedDisplay == .system, !draft.components.isEmpty {
                if family == .systemSmall || family == .accessoryRectangular {
                    let component = draft.components[0]
                    miniMetric(component.title, componentValue(component), symbolForKind(component.kind))
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], spacing: 6) {
                        ForEach(0..<min(draft.components.count, 4), id: \.self) { index in
                            let component = draft.components[index]
                            miniMetric(component.title, componentValue(component), symbolForKind(component.kind))
                        }
                    }
                }
            } else if family != .systemSmall {
                HStack(spacing: 8) {
                    miniMetric("Updated", entry.date.formatted(date: .omitted, time: .shortened), "clock")
                    miniMetric(entry.draft == nil ? "Mode" : "Draft", entry.draft?.theme ?? title, icon)
                }
            }

            Spacer(minLength: 0)

            Text("Open Toolkit")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
        }
        .containerBackground(background, for: .widget)
        .widgetURL(URL(string: "ultimatetoolkit://widget"))
    }

    private var title: String {
        if let draft = entry.draft, entry.configuration.resolvedDisplay == .system {
            return draft.name
        }
        switch entry.configuration.resolvedDisplay {
        case .system: return "System"
        case .sensors: return "Sensors"
        case .network: return "Network"
        case .shortcuts: return "Shortcuts"
        }
    }

    private var primary: String {
        if let draft = entry.draft, entry.configuration.resolvedDisplay == .system {
            return draft.components.isEmpty ? "Blank widget" : draft.theme
        }
        switch entry.configuration.resolvedDisplay {
        case .system: return "Device toolkit ready"
        case .sensors: return "Start live logging"
        case .network: return "Run diagnostics"
        case .shortcuts: return "Connector actions"
        }
    }

    private func componentValue(_ component: SharedWidgetComponent) -> String {
        switch component.binding {
        case "sensor.battery": return "Battery"
        case "sensor.battery.trend": return "Trend"
        case "sensor.thermal": return "Thermal"
        case "sensor.storage": return "Storage"
        case "sensor.count": return "Sensors"
        case "sensor.location": return "Location"
        case "network.status": return "Network"
        case "nfc.status": return "NFC"
        case "haptics.count": return "Saved"
        case "asset.local": return "Image"
        case "text.custom": return "Custom"
        default: return component.kind
        }
    }

    private func symbolForKind(_ kind: String) -> String {
        switch kind {
        case "Gauge": return "gauge.with.dots.needle.67percent"
        case "Chart": return "chart.xyaxis.line"
        case "Sensor": return "waveform.path.ecg"
        case "Image": return "photo"
        case "Battery": return "battery.100percent"
        case "Network": return "wifi"
        case "Thermal": return "thermometer.medium"
        case "Storage": return "internaldrive"
        case "Location": return "location"
        case "NFC": return "wave.3.right"
        case "Haptics": return "waveform.path"
        default: return "textformat"
        }
    }

    private var icon: String {
        switch entry.configuration.resolvedDisplay {
        case .system: return "iphone.gen3"
        case .sensors: return "waveform.path.ecg"
        case .network: return "network"
        case .shortcuts: return "point.3.connected.trianglepath.dotted"
        }
    }

    private var tint: Color {
        if let accent = entry.draft?.accent, entry.configuration.resolvedDisplay == .system {
            switch accent {
            case "Green": return Color.green
            case "Orange": return Color.orange
            case "Pink": return Color.pink
            case "Purple": return Color.purple
            case "Cyan": return Color.cyan
            default: return Color.blue
            }
        }
        switch entry.configuration.resolvedDisplay {
        case .system: return Color.blue
        case .sensors: return Color.green
        case .network: return Color.cyan
        case .shortcuts: return Color.purple
        }
    }

    private var background: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.11),
                tint.opacity(0.38)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func miniMetric(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Image(systemName: symbol)
                .font(.caption)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct SharedWidgetDraft: Decodable {
    let name: String
    let theme: String
    let background: String
    let accent: String?
    let components: [SharedWidgetComponent]
}

struct SharedWidgetComponent: Decodable {
    let kind: String
    let binding: String
    let title: String
}

struct ToolkitStatusWidget: Widget {
    let kind = "ToolkitStatusWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ToolkitWidgetConfigurationIntent.self, provider: ToolkitWidgetProvider()) { entry in
            ToolkitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Toolkit Status")
        .description("Quick launcher and status widget for Ultimate ToolKit.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

@main
struct UltimateToolKitWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ToolkitStatusWidget()
    }
}
