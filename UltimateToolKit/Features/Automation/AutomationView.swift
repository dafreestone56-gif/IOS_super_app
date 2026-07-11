import SwiftUI

struct AutomationView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var selectedSegment = "My Automations"
    @State private var enableAutomation = true
    @State private var runImmediately = false
    @State private var notifyWhenRun = true
    @State private var title = ""
    @State private var trigger = ""
    @State private var action = ""
    @State private var selectedTrigger = "Manual"
    @State private var selectedAction = "Log event"
    @State private var dryRunResult = ""

    private let triggerOptions = ["Manual", "Battery below threshold", "Network offline", "NFC tag scanned", "BLE device discovered", "Time scheduled"]
    private let actionOptions = ["Log event", "Show notification", "Play haptic", "Open module", "HTTP request"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Automation Source", selection: $selectedSegment) {
                    Text("My Automations").tag("My Automations")
                    Text("Templates").tag("Templates")
                }
                .pickerStyle(.segmented)

                GlassPanel {
                    VStack(spacing: 0) {
                        if services.automations.rules.isEmpty {
                            emptyState("No automations yet. Create one below, then run it manually or keep it enabled for future trigger wiring.")
                        } else {
                            ForEach(services.automations.rules) { rule in
                                automationRow(rule)
                                Divider().background(AppTheme.hairline)
                            }
                        }
                    }
                }

                SectionLabel(title: "Create Automation")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Name", text: $title)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        Picker("Trigger", selection: $selectedTrigger) {
                            ForEach(triggerOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        TextField("Trigger detail, threshold, tag id, host, or schedule", text: $trigger)
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        Picker("Action", selection: $selectedAction) {
                            ForEach(actionOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        TextField("Action detail, module, URL, or message", text: $action)
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))

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
                                services.log("Automation created")
                                if runImmediately {
                                    let line = services.automations.run(rule)
                                    services.log(line)
                                }
                                title = ""
                                trigger = ""
                                action = ""
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

                GlassPanel {
                    VStack(spacing: 14) {
                        Toggle("Enable Automation", isOn: $enableAutomation)
                        Toggle("Run Immediately", isOn: $runImmediately)
                        Toggle("Notify When Run", isOn: $notifyWhenRun)
                    }
                }

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
            .padding(16)
        }
        .navigationTitle("Automation")
        .toolkitScreen()
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

    private var composedTrigger: String {
        trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedTrigger : "\(selectedTrigger): \(trigger)"
    }

    private var composedAction: String {
        action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedAction : "\(selectedAction): \(action)"
    }

    private var dryRunSummary: String {
        return """
        Rule: \(title.isEmpty ? "Untitled Automation" : title)
        Enabled: \(enableAutomation ? "Yes" : "No")
        Trigger: \(composedTrigger)
        Action: \(composedAction)
        Current network: \(services.network.status)
        Sensor snapshot count: \(services.sensors.metrics.count)
        Result: This dry run validates rule shape and current context. Background execution still follows iOS limits.
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

    private var tintForSelectedTrigger: String {
        switch selectedTrigger {
        case "Battery below threshold": return "orange"
        case "Network offline": return "blue"
        case "NFC tag scanned": return "orange"
        case "BLE device discovered": return "blue"
        default: return "purple"
        }
    }
}
