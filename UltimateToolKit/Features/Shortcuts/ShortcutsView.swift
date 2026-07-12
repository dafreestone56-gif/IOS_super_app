import SwiftUI

struct ShortcutsView: View {
    private let categories: [ToolItem] = [
        ToolItem(title: "Device", subtitle: "Battery, thermal, brightness, device summary", symbol: "iphone.gen3", tint: .green),
        ToolItem(title: "Sensors", subtitle: "Saved live logs, recent samples, CSV export", symbol: "waveform.path.ecg", tint: .mint),
        ToolItem(title: "Developer Tools", subtitle: "JSON, CSV, Base64, Hex, hashes, regex, URLs, colors", symbol: "curlybraces", tint: .blue),
        ToolItem(title: "Network", subtitle: "HTTP request, DNS lookup, TCP probe, network summary", symbol: "network", tint: .cyan),
        ToolItem(title: "NFC", subtitle: "Last tag and reader capability diagnostics", symbol: "wave.3.right.circle.fill", tint: .orange),
        ToolItem(title: "Haptics", subtitle: "List, play, and export saved sequences", symbol: "waveform.path", tint: .purple),
        ToolItem(title: "Widgets", subtitle: "List and export Widget Studio drafts", symbol: "square.grid.2x2", tint: .pink),
        ToolItem(title: "Automation", subtitle: "Run saved local automation rules", symbol: "gearshape.2.fill", tint: .indigo),
        ToolItem(title: "App Launchers", subtitle: "Open hardware-gated modules from Shortcuts", symbol: "arrow.up.forward.app", tint: .cyan)
    ]

    private let actions = [
        "Get Device Summary",
        "Get Battery Level",
        "Get Thermal State",
        "Get Screen Brightness",
        "Get Sensor Log Summary",
        "Get Latest Sensor Samples",
        "Export Sensor Log CSV",
        "Validate / Format / Minify JSON",
        "CSV to JSON",
        "Base64 Encode / Decode",
        "Hex Encode",
        "SHA-256 and HMAC SHA-256",
        "Decode JWT",
        "Regex Matches",
        "Parse URL",
        "Color Contrast",
        "Run HTTP Request",
        "DNS Lookup",
        "TCP Port Probe",
        "Get Network Summary",
        "Get Last NFC Tag",
        "Get NFC Reader Status",
        "Play Haptic",
        "List Haptic Sequences",
        "Play Saved Haptic Sequence",
        "Export Haptic AHAP",
        "List Widget Drafts",
        "Get Widget Draft JSON",
        "Run Automation Rule",
        "Copy Text to Clipboard",
        "Open Toolkit Module"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Apple Shortcuts Actions")
                            .font(.headline)
                        Text("Saved haptics, widget drafts, automation rules, and logged sensors appear as choices inside the Shortcuts app where iOS supports dynamic options.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SectionLabel(title: "Categories")
                GlassPanel {
                    VStack(spacing: 0) {
                        ForEach(categories) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.symbol)
                                    .foregroundStyle(item.tint)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Spacer()
                                Text("Available")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                            .padding(.vertical, 10)
                            Divider().background(AppTheme.hairline)
                        }
                    }
                }

                SectionLabel(title: "Actions")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(actions, id: \.self) { action in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(action)
                                    .font(.caption)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Apple Shortcuts")
        .toolkitScreen()
    }
}
