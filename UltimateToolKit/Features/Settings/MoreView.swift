import AVFoundation
import CoreLocation
import Security
import SwiftUI

#if canImport(CoreNFC)
import CoreNFC
#endif

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
    @EnvironmentObject private var services: ToolkitServices
    @State private var providerKey = ""
    @State private var keyStatus = KeychainHelper.hasValue(account: "ai.provider.key") ? "Stored in Keychain" : "No provider key stored"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Privacy")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        permissionRow("Bluetooth", services.bluetooth.stateDescription, "bolt.horizontal.circle.fill", .blue)
                        permissionRow("NFC", nfcStatus, "wave.3.right.circle.fill", .orange)
                        permissionRow("Camera", cameraStatus, "camera.fill", .cyan)
                        permissionRow("Microphone", services.audio.permissionStatus, "mic.fill", .indigo)
                        permissionRow("Location", locationStatus, "location.fill", .green)
                    }
                }

                SectionLabel(title: "Data")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Local-first storage")
                            .font(.headline)
                        Text("Histories, automations, widget drafts, and secrets should remain on device. API keys belong in Keychain.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        HStack {
                            Button("Clear NFC History") {
                                services.nfc.clearHistory()
                                services.log("NFC history cleared from Settings")
                            }
                            .buttonStyle(.bordered)
                            Button("Clear Network History") {
                                services.network.clearHistory()
                                services.log("Network history cleared from Settings")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SectionLabel(title: "Secrets")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("AI provider API key", text: $providerKey)
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        Text(keyStatus)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        HStack {
                            Button("Save Key") {
                                if KeychainHelper.save(providerKey, account: "ai.provider.key") {
                                    providerKey = ""
                                    keyStatus = "Stored in Keychain"
                                    services.log("Provider key saved to Keychain")
                                } else {
                                    keyStatus = "Keychain save failed"
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(providerKey.isEmpty)
                            Button("Delete Key") {
                                KeychainHelper.delete(account: "ai.provider.key")
                                keyStatus = "No provider key stored"
                                services.log("Provider key deleted from Keychain")
                            }
                            .buttonStyle(.bordered)
                        }
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

    private var cameraStatus: String {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: "Authorized"
        case .denied: "Denied"
        case .restricted: "Restricted"
        case .notDetermined: "Not requested"
        @unknown default: "Unknown"
        }
    }

    private var locationStatus: String {
        switch CLLocationManager().authorizationStatus {
        case .authorizedAlways: "Always"
        case .authorizedWhenInUse: "When in use"
        case .denied: "Denied"
        case .restricted: "Restricted"
        case .notDetermined: "Not requested"
        @unknown default: "Unknown"
        }
    }

    private var nfcStatus: String {
        #if canImport(CoreNFC)
        NFCNDEFReaderSession.readingAvailable ? "Available" : "Unavailable"
        #else
        "Unavailable"
        #endif
    }
}

enum KeychainHelper {
    private static let service = "UltimateToolKit"

    static func save(_ value: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func hasValue(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
