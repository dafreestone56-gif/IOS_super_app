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
                        TextField("Trigger", text: $trigger)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        TextField("Action", text: $action)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))

                        HStack {
                            Button {
                                services.automations.add(title: title, trigger: trigger, action: action)
                                services.log("Automation created")
                                title = ""
                                trigger = ""
                                action = ""
                            } label: {
                                Label("Save Rule", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                trigger = "Battery Level < 20%"
                                action = "Show Notification"
                                title = "Low Battery Alert"
                            } label: {
                                Label("Battery Rule", systemImage: "battery.25")
                            }
                            .buttonStyle(.bordered)
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
                services.automations.run(rule)
                services.log("Automation ran: \(rule.title)")
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
}
