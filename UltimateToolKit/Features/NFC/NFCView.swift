import SwiftUI

struct NFCView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var writeText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    HStack(spacing: 12) {
                        Image(systemName: "wave.3.right.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NFC Reader / Writer")
                                .font(.headline)
                            Text(services.nfc.status)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Button("Scan") {
                            services.nfc.beginRead()
                            services.log("NFC read session requested")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if let result = services.nfc.lastResult {
                    SectionLabel(title: "Last Scan")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.title)
                                .font(.headline)
                            Text(result.detail)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text(result.payload)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(AppTheme.primaryText)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                SectionLabel(title: "Write NDEF")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Text or URL", text: $writeText)
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        Button {
                            services.nfc.beginWrite(text: writeText)
                            services.log("NFC write session requested")
                        } label: {
                            Label("Write Tag", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(writeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Text("iOS only writes supported NDEF tags after you explicitly start a scan.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                SectionLabel(title: "History")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        if services.nfc.history.isEmpty {
                            Text("Scanned and written tags will appear here.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        } else {
                            ForEach(services.nfc.history) { item in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.subheadline)
                                    Text(item.payload)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .lineLimit(2)
                                }
                                Divider().background(AppTheme.hairline)
                            }
                            Button("Clear History") {
                                services.nfc.clearHistory()
                                services.log("NFC history cleared")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .navigationTitle("NFC")
        .toolkitScreen()
    }
}
