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
    var display: ToolkitWidgetDisplay

    init() {
        display = .system
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
        guard let data = UserDefaults(suiteName: "group.com.personal.playgroundtoolkit")?.data(forKey: "widget.latestDraft") else {
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

            if family != .systemSmall {
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
        if let draft = entry.draft, entry.configuration.display == .system {
            return draft.name
        }
        switch entry.configuration.display {
        case .system: "System"
        case .sensors: "Sensors"
        case .network: "Network"
        case .shortcuts: "Shortcuts"
        }
    }

    private var primary: String {
        if let draft = entry.draft, entry.configuration.display == .system {
            return "\(draft.components.count) saved component\(draft.components.count == 1 ? "" : "s")"
        }
        switch entry.configuration.display {
        case .system: "Device toolkit ready"
        case .sensors: "Start live logging"
        case .network: "Run diagnostics"
        case .shortcuts: "Connector actions"
        }
    }

    private var icon: String {
        switch entry.configuration.display {
        case .system: "iphone.gen3"
        case .sensors: "waveform.path.ecg"
        case .network: "network"
        case .shortcuts: "point.3.connected.trianglepath.dotted"
        }
    }

    private var tint: Color {
        if let accent = entry.draft?.accent, entry.configuration.display == .system {
            switch accent {
            case "Green": return .green
            case "Orange": return .orange
            case "Pink": return .pink
            case "Purple": return .purple
            case "Cyan": return .cyan
            default: return .blue
            }
        }
        switch entry.configuration.display {
        case .system: .blue
        case .sensors: .green
        case .network: .cyan
        case .shortcuts: .purple
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
