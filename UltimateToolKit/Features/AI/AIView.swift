import SwiftUI

struct AIView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var prompt = ""
    @State private var output = "AI features are opt-in. Add a provider key in Settings before cloud requests are enabled."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI Lab", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.mint)
                        Text("Draft automations, widget layouts, JSON transforms, and code snippets. Cloud calls must be explicitly configured with a user-owned API key.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                TextEditor(text: $prompt)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 130)
                    .padding(8)
                    .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))

                HStack {
                    Button {
                        output = draftAutomation(from: prompt)
                        services.log("AI automation draft generated locally")
                    } label: {
                        Label("Draft Automation", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        output = "Provider setup belongs in Keychain-backed Settings before cloud AI is enabled."
                    } label: {
                        Label("Provider", systemImage: "key")
                    }
                    .buttonStyle(.bordered)
                }

                SectionLabel(title: "Output")
                Text(output)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(16)
        }
        .navigationTitle("AI Lab")
        .toolkitScreen()
    }

    private func draftAutomation(from prompt: String) -> String {
        let lower = prompt.lowercased()
        let trigger: String
        if lower.contains("battery") {
            trigger = "Battery below threshold"
        } else if lower.contains("wifi") || lower.contains("network") || lower.contains("http") {
            trigger = "Network status or HTTP result"
        } else if lower.contains("bluetooth") || lower.contains("ble") {
            trigger = "BLE device discovered"
        } else if lower.contains("nfc") || lower.contains("tag") {
            trigger = "NFC tag scanned"
        } else if lower.contains("time") || lower.contains("schedule") {
            trigger = "Time scheduled"
        } else {
            trigger = "Manual"
        }

        let action: String
        if lower.contains("haptic") || lower.contains("vibrate") {
            action = "Play haptic"
        } else if lower.contains("webhook") || lower.contains("http") || lower.contains("url") {
            action = "HTTP request"
        } else if lower.contains("open") {
            action = "Open module"
        } else {
            action = "Log event"
        }

        let module: String
        if lower.contains("widget") {
            module = "Widget Studio"
        } else if lower.contains("camera") || lower.contains("qr") || lower.contains("ocr") {
            module = "Camera"
        } else if lower.contains("audio") || lower.contains("mic") {
            module = "Audio"
        } else if lower.contains("json") || lower.contains("base64") || lower.contains("regex") {
            module = "Developer Tools"
        } else {
            module = "Automation"
        }

        return """
        Local Draft
        Module: \(module)
        Trigger: \(trigger)
        Action: \(action)
        Review required: Yes
        Cloud used: No

        Source prompt:
        \(prompt)
        """
    }
}
