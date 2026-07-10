import SwiftUI

struct MoreView: View {
    private let modules: [ToolkitModule] = [.camera, .audio, .haptics, .developerTools, .ai, .settings]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Modules")
                GlassPanel {
                    VStack(spacing: 0) {
                        ForEach(modules) { module in
                            NavigationLink(value: module) {
                                ToolRow(module: module)
                            }
                            .buttonStyle(.plain)
                            Divider().background(AppTheme.hairline)
                        }
                    }
                }

                SectionLabel(title: "Build")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unsigned personal build")
                            .font(.headline)
                        Text("GitHub Actions will compile an unsigned IPA for user-side signing and sideloading.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .navigationTitle("More")
        .toolkitScreen()
    }
}

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Privacy")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        permissionRow("Bluetooth", "Requested when scanning BLE peripherals", "bolt.horizontal.circle.fill", .blue)
                        permissionRow("NFC", "Requested when starting a tag session", "wave.3.right.circle.fill", .orange)
                        permissionRow("Camera", "Requested for Vision and capture tools", "camera.fill", .cyan)
                        permissionRow("Microphone", "Requested for audio analysis and speech", "mic.fill", .indigo)
                        permissionRow("Location", "Requested for compass, geofence, and Wi-Fi metadata", "location.fill", .green)
                    }
                }

                SectionLabel(title: "Data")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Local-first storage")
                            .font(.headline)
                        Text("Histories, automations, widget drafts, and secrets should remain on device. API keys belong in Keychain.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .navigationTitle("Settings")
        .toolkitScreen()
    }

    private func permissionRow(_ title: String, _ detail: String, _ symbol: String, _ tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}
