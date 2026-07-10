import SwiftUI

struct NetworkView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var url = ""
    @State private var response = "Run an HTTP request to inspect the response."
    @State private var isLoading = false
    @State private var probeHost = ""
    @State private var probePort = "443"
    @State private var probeResult = "Run a TCP probe to test host/port reachability."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Current Network", systemImage: "wifi")
                                .font(.headline)
                            Spacer()
                            Text(services.network.status)
                                .foregroundStyle(services.network.status == "Online" ? .green : .orange)
                        }
                        metricRow("Interfaces", services.network.activeInterfaces.isEmpty ? "Detecting" : services.network.activeInterfaces.joined(separator: ", "))
                        metricRow("IP Addresses", services.network.ipAddresses.isEmpty ? "Not detected" : services.network.ipAddresses.joined(separator: "\n"))
                        metricRow("Cost", services.network.isExpensive ? "Expensive" : "Standard")
                        metricRow("SSID", "Requires Access WiFi Information entitlement")
                    }
                }

                SectionLabel(title: "HTTP Client")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("URL", text: $url)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))

                        Button {
                            Task { @MainActor in
                                isLoading = true
                                let result = await services.network.httpGet(url)
                                response = result
                                services.log("HTTP GET completed")
                                isLoading = false
                            }
                        } label: {
                            Label(isLoading ? "Running" : "Send GET", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading)

                        Button {
                            services.network.refreshInterfaces()
                            services.log("Network interfaces refreshed")
                        } label: {
                            Label("Refresh Interfaces", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)

                        Text(response)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(AppTheme.primaryText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                SectionLabel(title: "Tools")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TCP Port Probe")
                            .font(.headline)
                        HStack {
                            TextField("Host", text: $probeHost)
                                .textInputAutocapitalization(.never)
                                .padding(10)
                                .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                            TextField("Port", text: $probePort)
                                .keyboardType(.numberPad)
                                .frame(width: 82)
                                .padding(10)
                                .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        }
                        Button {
                            Task { @MainActor in
                                let port = UInt16(probePort) ?? 0
                                probeResult = await services.network.tcpProbe(host: probeHost, port: port)
                                services.log("TCP probe completed")
                            }
                        } label: {
                            Label("Probe", systemImage: "rectangle.connected.to.line.below")
                        }
                        .buttonStyle(.borderedProminent)
                        Text(probeResult)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(AppTheme.secondaryText)
                            .textSelection(.enabled)

                        Divider().background(AppTheme.hairline)
                        toolLine("ICMP Ping", "Requires real-device ICMP implementation validation", "timer")
                        toolLine("LAN Scanner", "Subnet scan should be rate-limited before enabling", "dot.radiowaves.left.and.right")
                        toolLine("Bonjour Browser", "mDNS service discovery through NetServiceBrowser", "network")
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Wi-Fi")
        .toolkitScreen()
    }

    private func metricRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }

    private func toolLine(_ title: String, _ subtitle: String, _ symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.cyan)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.vertical, 10)
    }
}
