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
        """
        Draft Automation
        IF Battery Level is less than 20%
        THEN Show Notification "Low Battery"
        THEN Optional: play haptic preset "Warning"

        Source prompt:
        \(prompt)
        """
    }
}
