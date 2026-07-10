import SwiftUI

struct ShortcutsView: View {
    private let categories: [ToolItem] = [
        ToolItem(title: "Sensors", subtitle: "Battery, thermal, motion, display", symbol: "waveform.path.ecg", tint: .green),
        ToolItem(title: "Developer Tools", subtitle: "JSON, Base64, hashes, regex", symbol: "curlybraces", tint: .blue),
        ToolItem(title: "Bluetooth", subtitle: "Scan, connect, read, write", symbol: "bolt.horizontal.circle.fill", tint: .blue),
        ToolItem(title: "NFC", subtitle: "Read tag, last scan, write text", symbol: "wave.3.right.circle.fill", tint: .orange),
        ToolItem(title: "Network", subtitle: "HTTP, ping, DNS, Wi-Fi info", symbol: "network", tint: .cyan),
        ToolItem(title: "Automation", subtitle: "Run rule, log event, notify", symbol: "gearshape.2.fill", tint: .purple)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AppIntents Catalog")
                            .font(.headline)
                        Text("AppIntents expose battery reads and JSON formatting now. The catalog below tracks action coverage for each module.")
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
                                Text("Planned")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(.vertical, 10)
                            Divider().background(AppTheme.hairline)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Shortcuts")
        .toolkitScreen()
    }
}
