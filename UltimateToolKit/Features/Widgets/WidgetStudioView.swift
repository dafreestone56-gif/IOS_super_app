import SwiftUI

struct WidgetStudioView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var draftName = "Toolkit Widget"
    @State private var cornerRadius = 16.0
    @State private var theme = "System"
    @State private var background = "Blur"
    @State private var accent = "Blue"
    @State private var components: [WidgetDraftComponent] = [
        WidgetDraftComponent(kind: "Battery", binding: "sensor.battery", title: "Battery"),
        WidgetDraftComponent(kind: "Network", binding: "network.status", title: "Network")
    ]
    @State private var drafts: [WidgetDraft] = AppPersistence.load([WidgetDraft].self, key: "widget.drafts", fallback: [])
    private let themes = ["System", "Compact", "Instrument", "Terminal"]
    private let backgrounds = ["Blur", "Graphite", "Midnight", "Glass", "High Contrast"]
    private let accents = ["Blue", "Green", "Orange", "Pink", "Purple", "Cyan"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                widgetPreview

                GlassPanel {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "iphone.and.arrow.forward")
                            .font(.title2)
                            .foregroundStyle(accentColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Home Screen Widget")
                                .font(.headline)
                            Text("Toolkit Status is included as a WidgetKit extension and appears in the iOS widget gallery after install.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SectionLabel(title: "Add Component")
                GlassPanel {
                    HStack(spacing: 10) {
                        componentButton("Text", "textformat")
                        componentButton("Gauge", "gauge.with.dots.needle.67percent")
                        componentButton("Chart", "chart.xyaxis.line")
                        componentButton("Sensor", "waveform.path.ecg")
                        componentButton("Image", "photo")
                    }
                }

                if !components.isEmpty {
                    SectionLabel(title: "Components")
                    GlassPanel {
                        VStack(spacing: 0) {
                            ForEach(components) { component in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(component.title)
                                        Text("\(component.kind) -> \(component.binding)")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    Button {
                                        components.removeAll { $0.id == component.id }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.vertical, 8)
                                Divider().background(AppTheme.hairline)
                            }
                        }
                    }
                }

                GlassPanel {
                    VStack(spacing: 16) {
                        TextField("Draft name", text: $draftName)
                            .textInputAutocapitalization(.words)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        settingPicker("Theme", selection: $theme, options: themes)
                        settingPicker("Background", selection: $background, options: backgrounds)
                        settingPicker("Accent", selection: $accent, options: accents)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Corner Radius")
                                Spacer()
                                Text(Int(cornerRadius).description)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Slider(value: $cornerRadius, in: 0...28, step: 1)
                        }
                    }
                }

                if !drafts.isEmpty {
                    SectionLabel(title: "Saved Drafts")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(drafts.prefix(5)) { draft in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(draft.name)
                                    Text("\(draft.components.count) components  \(draft.theme) / \(draft.background) / \(draft.accent)  Updated \(draft.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Divider().background(AppTheme.hairline)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Widget Studio")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { saveDraft() } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
        .toolkitScreen()
        .onAppear {
            services.sensors.refreshSnapshot()
            services.network.refreshInterfaces()
        }
    }

    private var widgetPreview: some View {
        let battery = metricValue("Battery")
        let thermal = metricValue("Thermal State")
        let storage = metricValue("Storage")
        let trend = services.sensors.metrics.first(where: { $0.title == "Battery" })?.trend ?? []

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.25), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: batteryFraction)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "battery.100percent")
                        .foregroundStyle(accentColor)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading) {
                    Text("Battery")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(battery)
                        .font(.title.bold())
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Thermal")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(thermal)
                        .font(.headline)
                    Sparkline(values: trend, tint: accentColor)
                        .frame(width: 96, height: 28)
                }
            }

            HStack(spacing: 8) {
                ForEach(components.prefix(4)) { component in
                    smallWidgetMetric(component.title, valueForBinding(component.binding, fallback: storage), symbolForKind(component.kind))
                }
            }
        }
        .padding(18)
        .background(previewBackground, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(AppTheme.hairline))
    }

    private func smallWidgetMetric(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(accentColor)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
    }

    private func componentButton(_ title: String, _ symbol: String) -> some View {
        Button {
            components.append(WidgetDraftComponent(kind: title, binding: defaultBinding(for: title), title: title))
            services.log("Widget component added: \(title)")
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.headline)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
    }

    private func settingPicker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        HStack {
            Text(title)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func metricValue(_ title: String) -> String {
        services.sensors.metrics.first(where: { $0.title == title })?.value ?? "--"
    }

    private var batteryFraction: Double {
        let raw = metricValue("Battery").replacingOccurrences(of: "%", with: "")
        return min(1, max(0, (Double(raw) ?? 0) / 100))
    }

    private func defaultBinding(for title: String) -> String {
        switch title {
        case "Gauge": return "sensor.battery"
        case "Chart": return "sensor.battery.trend"
        case "Sensor": return "sensor.count"
        case "Image": return "asset.local"
        default: return "text.custom"
        }
    }

    private func valueForBinding(_ binding: String, fallback: String) -> String {
        switch binding {
        case "sensor.battery", "sensor.battery.trend":
            return metricValue("Battery")
        case "network.status":
            return services.network.status
        case "sensor.count":
            return "\(services.sensors.metrics.count)"
        case "asset.local":
            return "Image"
        case "text.custom":
            return "Text"
        default:
            return fallback
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
        default: return "textformat"
        }
    }

    private var accentColor: Color {
        switch accent {
        case "Green": return Color.green
        case "Orange": return Color.orange
        case "Pink": return Color.pink
        case "Purple": return Color.purple
        case "Cyan": return Color.cyan
        default: return Color.blue
        }
    }

    private var previewBackground: AnyShapeStyle {
        switch background {
        case "Graphite": return AnyShapeStyle(Color(red: 0.12, green: 0.13, blue: 0.14))
        case "Midnight": return AnyShapeStyle(Color(red: 0.05, green: 0.07, blue: 0.12))
        case "Glass": return AnyShapeStyle(.regularMaterial)
        case "High Contrast": return AnyShapeStyle(Color.black)
        default: return AnyShapeStyle(.ultraThinMaterial)
        }
    }

    private func saveDraft() {
        let cleanName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let draft = WidgetDraft(
            name: cleanName.isEmpty ? "Toolkit Widget \(drafts.count + 1)" : cleanName,
            theme: theme,
            background: background,
            accent: accent,
            cornerRadius: cornerRadius,
            components: components,
            updatedAt: Date()
        )
        drafts.removeAll { $0.name.caseInsensitiveCompare(draft.name) == .orderedSame }
        drafts.insert(draft, at: 0)
        drafts = Array(drafts.prefix(20))
        AppPersistence.save(drafts, key: "widget.drafts")
        if let data = try? JSONEncoder().encode(draft), let json = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(data, forKey: "widget.latestDraft")
            UserDefaults(suiteName: "group.com.personal.playgroundtoolkit")?.set(data, forKey: "widget.latestDraft")
            services.log(json)
        } else {
            services.log("Widget draft saved")
        }
    }
}
