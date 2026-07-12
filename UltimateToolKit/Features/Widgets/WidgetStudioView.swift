import SwiftUI
import WidgetKit

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
    @State private var selectedDraftID: UUID?
    @State private var widgetSharingStatus = ""
    private let themes = ["System", "Compact", "Instrument", "Terminal"]
    private let backgrounds = ["Blur", "Graphite", "Midnight", "Glass", "High Contrast"]
    private let accents = ["Blue", "Green", "Orange", "Pink", "Purple", "Cyan"]
    private let componentChoices = ["Text", "Battery", "Thermal", "Storage", "Network", "Gauge", "Chart", "Sensor", "Location", "NFC", "Haptics", "Image"]

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
                            Text(widgetSharingStatus)
                                .font(.caption2)
                                .foregroundStyle(widgetSharingStatus.contains("unavailable") ? .orange : .green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SectionLabel(title: "Add Component")
                GlassPanel {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], spacing: 8) {
                        ForEach(componentChoices, id: \.self) { choice in
                            componentButton(choice, symbolForKind(choice))
                        }
                    }
                }

                SectionLabel(title: "Components")
                GlassPanel {
                    VStack(spacing: 0) {
                        HStack {
                            Text("\(components.count) active")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Button {
                                components.removeAll()
                            } label: {
                                Image(systemName: "trash.slash")
                            }
                            .buttonStyle(.bordered)
                            .disabled(components.isEmpty)
                            .accessibilityLabel("Clear components")
                        }
                        .padding(.bottom, components.isEmpty ? 0 : 8)

                        if components.isEmpty {
                            Text("Add any components above to build the widget from a blank canvas.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
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
                                        moveComponent(component, by: -1)
                                    } label: {
                                        Image(systemName: "chevron.up")
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(componentIndex(component) == 0)
                                    .accessibilityLabel("Move \(component.title) up")
                                    Button {
                                        moveComponent(component, by: 1)
                                    } label: {
                                        Image(systemName: "chevron.down")
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(componentIndex(component) == components.count - 1)
                                    .accessibilityLabel("Move \(component.title) down")
                                    Button {
                                        components.removeAll { $0.id == component.id }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                    .accessibilityLabel("Remove \(component.title)")
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
                            ForEach(drafts) { draft in
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(draft.name)
                                        Text("\(draft.components.count) components  \(draft.theme) / \(draft.background) / \(draft.accent)  Updated \(draft.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    Button {
                                        loadDraft(draft)
                                    } label: {
                                        Image(systemName: "arrow.down.doc")
                                    }
                                    .buttonStyle(.bordered)
                                    .accessibilityLabel("Load \(draft.name)")
                                    Button {
                                        publishDraft(draft)
                                    } label: {
                                        Image(systemName: selectedDraftID == draft.id ? "iphone.and.arrow.forward.circle.fill" : "iphone.and.arrow.forward")
                                    }
                                    .buttonStyle(.bordered)
                                    .accessibilityLabel("Use \(draft.name) for home screen widget")
                                    Button(role: .destructive) {
                                        deleteDraft(draft)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                    .accessibilityLabel("Delete \(draft.name)")
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
            updateWidgetSharingStatus()
        }
    }

    private var widgetPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.stack")
                    .foregroundStyle(accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Toolkit Widget" : draftName)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(components.count) components  \(theme) / \(background)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer(minLength: 0)
            }

            if components.isEmpty {
                Text("Blank widget canvas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
                    .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                    ForEach(components.prefix(8)) { component in
                        smallWidgetMetric(component.title, valueForBinding(component.binding, fallback: "--"), symbolForKind(component.kind))
                    }
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

    private func defaultBinding(for title: String) -> String {
        switch title {
        case "Battery": return "sensor.battery"
        case "Thermal": return "sensor.thermal"
        case "Storage": return "sensor.storage"
        case "Network": return "network.status"
        case "Gauge": return "sensor.battery"
        case "Chart": return "sensor.battery.trend"
        case "Sensor": return "sensor.count"
        case "Location": return "sensor.location"
        case "NFC": return "nfc.status"
        case "Haptics": return "haptics.count"
        case "Image": return "asset.local"
        default: return "text.custom"
        }
    }

    private func valueForBinding(_ binding: String, fallback: String) -> String {
        switch binding {
        case "sensor.battery", "sensor.battery.trend":
            return metricValue("Battery")
        case "sensor.thermal":
            return metricValue("Thermal State")
        case "sensor.storage":
            return metricValue("Storage")
        case "network.status":
            return services.network.status
        case "sensor.count":
            return "\(services.sensors.metrics.count)"
        case "sensor.location":
            return metricValue("Location")
        case "nfc.status":
            return services.nfc.status
        case "haptics.count":
            let sequences = AppPersistence.load([SavedHapticSequence].self, key: "haptic.sequences", fallback: [])
            return "\(sequences.count) saved"
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
        case "Thermal": return "thermometer.medium"
        case "Storage": return "internaldrive"
        case "Location": return "location"
        case "NFC": return "wave.3.right"
        case "Haptics": return "waveform.path"
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
        case "Glass": return AnyShapeStyle(Color.white.opacity(0.12))
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
        publishDraft(draft)
    }

    private func loadDraft(_ draft: WidgetDraft) {
        draftName = draft.name
        theme = draft.theme
        background = draft.background
        accent = draft.accent
        cornerRadius = draft.cornerRadius
        components = draft.components
        selectedDraftID = draft.id
        services.log("Loaded widget draft: \(draft.name)")
    }

    private func publishDraft(_ draft: WidgetDraft) {
        guard let data = try? JSONEncoder().encode(draft) else {
            services.log("Widget draft could not be encoded", level: .warning)
            return
        }

        UserDefaults.standard.set(data, forKey: "widget.latestDraft")
        if let sharedDefaults = UserDefaults(suiteName: "group.com.personal.playgroundtoolkit") {
            sharedDefaults.set(data, forKey: "widget.latestDraft")
            widgetSharingStatus = "Draft sharing is available. Home Screen widgets will reload from saved drafts."
        } else {
            widgetSharingStatus = "Draft sharing is unavailable in this signed build. Edit the Home Screen widget directly for custom slots."
            services.log("App Group storage is unavailable. Check the signed App Group entitlement.", level: .warning)
        }
        selectedDraftID = draft.id
        WidgetCenter.shared.reloadAllTimelines()
        services.log("Widget draft published: \(draft.name)")
    }

    private func updateWidgetSharingStatus() {
        if UserDefaults(suiteName: "group.com.personal.playgroundtoolkit") == nil {
            widgetSharingStatus = "Draft sharing is unavailable in this signed build. Edit the Home Screen widget directly for custom slots."
        } else {
            widgetSharingStatus = "Draft sharing is available. Save a draft, then refresh the Home Screen widget."
        }
    }

    private func deleteDraft(_ draft: WidgetDraft) {
        drafts.removeAll { $0.id == draft.id }
        AppPersistence.save(drafts, key: "widget.drafts")
        if selectedDraftID == draft.id {
            selectedDraftID = nil
        }
        services.log("Deleted widget draft: \(draft.name)")
    }

    private func componentIndex(_ component: WidgetDraftComponent) -> Int {
        components.firstIndex { $0.id == component.id } ?? 0
    }

    private func moveComponent(_ component: WidgetDraftComponent, by offset: Int) {
        guard let source = components.firstIndex(where: { $0.id == component.id }) else { return }
        let destination = source + offset
        guard components.indices.contains(destination) else { return }
        components.swapAt(source, destination)
    }
}
