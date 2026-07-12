import SwiftUI

struct AutomationView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var selectedSegment = "Rules"
    @State private var enableAutomation = true
    @State private var runImmediately = false
    @State private var notifyWhenRun = true
    @State private var title = ""
    @State private var selectedTrigger = "Manual"
    @State private var selectedTriggerDetail = "Run from app"
    @State private var selectedAction = "Log event"
    @State private var selectedActionDetail = "Toolkit event"
    @State private var dryRunResult = ""

    private let triggerOptions = ["Manual", "Battery below threshold", "Network offline", "NFC tag scanned", "BLE device discovered", "Time scheduled"]
    private let actionOptions = ["Log event", "Show notification", "Play haptic", "Open module", "HTTP request"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Automation Source", selection: $selectedSegment) {
                    Text("Rules").tag("Rules")
                    Text("Templates").tag("Templates")
                }
                .pickerStyle(.segmented)

                automationOverview

                if selectedSegment == "Templates" {
                    templatesPanel
                } else {
                    rulesPanel
                    createPanel
                    optionsPanel
                    executionLogPanel
                }
            }
            .padding(16)
        }
        .navigationTitle("Automation")
        .toolkitScreen()
        .onAppear {
            normalizeSelections()
        }
        .onChange(of: selectedTrigger) { _ in
            selectedTriggerDetail = triggerDetailOptions.first ?? ""
        }
        .onChange(of: selectedAction) { _ in
            selectedActionDetail = actionDetailOptions.first ?? ""
        }
    }

    private var automationOverview: some View {
        GlassPanel {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "switch.2")
                    .font(.title2)
                    .foregroundStyle(.purple)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trigger -> Action")
                        .font(.headline)
                    Text("Build local rules from known device conditions, then run them manually or from Apple Shortcuts while iOS background hooks mature.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rulesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "My Rules")
            GlassPanel {
                VStack(spacing: 0) {
                    if services.automations.rules.isEmpty {
                        emptyState("No rules saved yet. Start from a template or create one below.")
                    } else {
                        ForEach(services.automations.rules) { rule in
                            automationRow(rule)
                            Divider().background(AppTheme.hairline)
                        }
                    }
                }
            }
        }
    }

    private var templatesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Starter Templates")
            ForEach(starterTemplates) { template in
                GlassPanel {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: template.symbol)
                            .font(.title3)
                            .foregroundStyle(template.tint)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.title)
                                .font(.headline)
                            Text("\(template.trigger): \(template.triggerDetail)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("\(template.action): \(template.actionDetail)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                        Spacer()
                        Button {
                            applyTemplate(template)
                        } label: {
                            Label("Use", systemImage: "plus.circle")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private var createPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Create Rule")
            GlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Rule name", text: $title)
                        .padding(10)
                        .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))

                    settingPicker("Trigger", selection: $selectedTrigger, options: triggerOptions)
                    settingPicker("Condition", selection: $selectedTriggerDetail, options: triggerDetailOptions)
                    settingPicker("Action", selection: $selectedAction, options: actionOptions)
                    settingPicker("Action Detail", selection: $selectedActionDetail, options: actionDetailOptions)

                    rulePreview

                    HStack {
                        Button {
                            let rule = services.automations.add(
                                title: title,
                                trigger: composedTrigger,
                                action: composedAction,
                                symbol: symbolForSelectedTrigger,
                                tintKey: tintForSelectedTrigger,
                                isEnabled: enableAutomation
                            )
                            services.log("Automation created: \(rule.title)")
                            if runImmediately {
                                let line = services.automations.run(rule)
                                services.log(line)
                            }
                            resetBuilder()
                        } label: {
                            Label("Save Rule", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            dryRunResult = dryRunSummary
                            services.log("Automation dry run completed")
                        } label: {
                            Label("Dry Run", systemImage: "play.circle")
                        }
                        .buttonStyle(.bordered)
                    }

                    if !dryRunResult.isEmpty {
                        Text(dryRunResult)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(AppTheme.secondaryText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private var optionsPanel: some View {
        GlassPanel {
            VStack(spacing: 14) {
                Toggle("Enable Rule", isOn: $enableAutomation)
                Toggle("Run Immediately After Saving", isOn: $runImmediately)
                Toggle("Log Result When Run", isOn: $notifyWhenRun)
            }
        }
    }

    @ViewBuilder
    private var executionLogPanel: some View {
        if !services.automations.executionLog.isEmpty {
            SectionLabel(title: "Execution Log")
            GlassPanel {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(services.automations.executionLog, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var rulePreview: some View {
        HStack(spacing: 10) {
            Label(composedTrigger, systemImage: symbolForSelectedTrigger)
                .lineLimit(2)
            Image(systemName: "arrow.right")
                .foregroundStyle(AppTheme.tertiaryText)
            Label(composedAction, systemImage: symbolForSelectedAction)
                .lineLimit(2)
        }
        .font(.caption)
        .foregroundStyle(AppTheme.secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
    }

    private func automationRow(_ rule: AutomationRule) -> some View {
        HStack {
            Image(systemName: rule.symbol)
                .foregroundStyle(rule.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.title)
                Text(rule.trigger)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(rule.action)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            Spacer()
            Button("Run") {
                let line = services.automations.run(rule)
                services.log("Automation ran: \(rule.title)")
                if notifyWhenRun {
                    services.log(line)
                }
            }
            .buttonStyle(.bordered)
            Button {
                services.automations.delete(rule)
                services.log("Automation deleted: \(rule.title)")
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { services.automations.setEnabled(rule, enabled: $0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 9)
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
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

    private var starterTemplates: [AutomationTemplate] {
        [
            AutomationTemplate(
                title: "Battery Pulse",
                trigger: "Battery below threshold",
                triggerDetail: "25%",
                action: "Play haptic",
                actionDetail: actionDetailOptionsForTemplate(action: "Play haptic").first ?? "Default success haptic",
                symbol: "battery.25",
                tint: .orange
            ),
            AutomationTemplate(
                title: "Network Drop Notice",
                trigger: "Network offline",
                triggerDetail: "Any interface",
                action: "Show notification",
                actionDetail: "Network status changed",
                symbol: "wifi.slash",
                tint: .cyan
            ),
            AutomationTemplate(
                title: "NFC Capture Log",
                trigger: "NFC tag scanned",
                triggerDetail: "Any NDEF tag",
                action: "Log event",
                actionDetail: "NFC scan captured",
                symbol: "wave.3.right.circle.fill",
                tint: .orange
            )
        ]
    }

    private var triggerDetailOptions: [String] {
        switch selectedTrigger {
        case "Battery below threshold": return ["15%", "25%", "50%"]
        case "Network offline": return ["Any interface", "Wi-Fi only", "Cellular only"]
        case "NFC tag scanned": return ["Any NDEF tag"] + services.nfc.history.prefix(5).map(\.title)
        case "BLE device discovered": return ["Any nearby BLE device", "Saved device", "Strong signal only"]
        case "Time scheduled": return ["Morning 8:00", "Evening 9:00", "Every hour while app is open"]
        default: return ["Run from app", "Run from Apple Shortcuts", "Run from widget"]
        }
    }

    private var actionDetailOptions: [String] {
        actionDetailOptionsForTemplate(action: selectedAction)
    }

    private func actionDetailOptionsForTemplate(action: String) -> [String] {
        switch action {
        case "Show notification": return ["Automation matched", "Network status changed", "Sensor threshold reached"]
        case "Play haptic":
            let names = AppPersistence.load([SavedHapticSequence].self, key: "haptic.sequences", fallback: []).map(\.name)
            return names.isEmpty ? ["Default success haptic"] : names
        case "Open module": return ToolkitModule.favorites.map(\.title) + ["Haptics", "Network", "Developer Tools", "Settings"]
        case "HTTP request": return ["GET https://example.com", "GET https://api.github.com", "POST local webhook"]
        default: return ["Toolkit event", "Append to execution log", "Capture current context"]
        }
    }

    private var composedTrigger: String {
        "\(selectedTrigger): \(selectedTriggerDetail)"
    }

    private var composedAction: String {
        "\(selectedAction): \(selectedActionDetail)"
    }

    private var dryRunSummary: String {
        return """
        Rule: \(title.isEmpty ? "Untitled Automation" : title)
        Enabled: \(enableAutomation ? "Yes" : "No")
        Trigger: \(composedTrigger)
        Action: \(composedAction)
        Current network: \(services.network.status)
        Sensor snapshot count: \(services.sensors.metrics.count)
        Result: Rule shape is valid for foreground/manual execution.
        """
    }

    private var symbolForSelectedTrigger: String {
        switch selectedTrigger {
        case "Battery below threshold": return "battery.25"
        case "Network offline": return "wifi.slash"
        case "NFC tag scanned": return "wave.3.right.circle.fill"
        case "BLE device discovered": return "bolt.horizontal.circle.fill"
        case "Time scheduled": return "clock"
        default: return "gearshape.2.fill"
        }
    }

    private var symbolForSelectedAction: String {
        switch selectedAction {
        case "Show notification": return "bell.badge"
        case "Play haptic": return "waveform.path"
        case "Open module": return "arrow.up.forward.app"
        case "HTTP request": return "network"
        default: return "doc.text"
        }
    }

    private var tintForSelectedTrigger: String {
        switch selectedTrigger {
        case "Battery below threshold": return "orange"
        case "Network offline": return "blue"
        case "NFC tag scanned": return "orange"
        case "BLE device discovered": return "blue"
        default: return "purple"
        }
    }

    private func applyTemplate(_ template: AutomationTemplate) {
        title = template.title
        selectedTrigger = template.trigger
        selectedTriggerDetail = template.triggerDetail
        selectedAction = template.action
        selectedActionDetail = template.actionDetail
        selectedSegment = "Rules"
        dryRunResult = ""
    }

    private func normalizeSelections() {
        if !triggerDetailOptions.contains(selectedTriggerDetail) {
            selectedTriggerDetail = triggerDetailOptions.first ?? ""
        }
        if !actionDetailOptions.contains(selectedActionDetail) {
            selectedActionDetail = actionDetailOptions.first ?? ""
        }
    }

    private func resetBuilder() {
        title = ""
        selectedTrigger = "Manual"
        selectedTriggerDetail = "Run from app"
        selectedAction = "Log event"
        selectedActionDetail = "Toolkit event"
        dryRunResult = ""
    }
}

private struct AutomationTemplate: Identifiable {
    let id = UUID()
    let title: String
    let trigger: String
    let triggerDetail: String
    let action: String
    let actionDetail: String
    let symbol: String
    let tint: Color
}
