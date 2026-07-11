import SwiftUI

struct NetworkView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var url = ""
    @State private var method = "GET"
    @State private var headers = ""
    @State private var requestBody = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var probeHost = ""
    @State private var probePort = "443"
    @State private var probeResult = ""
    @State private var dnsHost = ""
    @State private var dnsResult = ""
    @State private var scanPorts = "22,80,443"
    @State private var scanResult = ""
    @State private var bonjourType = "_http._tcp."
    @State private var wolMac = ""
    @State private var wolResult = ""

    private let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]

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
                        Picker("Method", selection: $method) {
                            ForEach(methods, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        TextField("URL", text: $url)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))

                        TextEditor(text: $headers)
                            .font(.system(.caption, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 58)
                            .padding(8)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .topLeading) {
                                if headers.isEmpty {
                                    Text("Headers, one per line: Authorization: Bearer ...")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.tertiaryText)
                                        .padding(14)
                                }
                            }

                        if !["GET", "HEAD"].contains(method) {
                            TextEditor(text: $requestBody)
                                .font(.system(.caption, design: .monospaced))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 88)
                                .padding(8)
                                .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                                .overlay(alignment: .topLeading) {
                                    if requestBody.isEmpty {
                                        Text("Request body")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.tertiaryText)
                                            .padding(14)
                                    }
                                }
                        }

                        Button {
                            Task { @MainActor in
                                isLoading = true
                                let result = await services.network.httpRequest(url: url, method: method, headers: headers, body: requestBody)
                                response = result
                                services.log("HTTP \(method) completed")
                                isLoading = false
                            }
                        } label: {
                            Label(isLoading ? "Running" : "Send \(method)", systemImage: "paperplane.fill")
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

                        resultText(response, empty: "Run an HTTP request to inspect status, duration, headers, and body.")
                    }
                }

                SectionLabel(title: "DNS")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Host name", text: $dnsHost)
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        Button {
                            Task { @MainActor in
                                dnsResult = await services.network.dnsLookup(host: dnsHost)
                                services.log("DNS lookup completed")
                            }
                        } label: {
                            Label("Lookup", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        resultText(dnsResult, empty: "Resolved addresses will appear here.")
                    }
                }

                SectionLabel(title: "TCP Tools")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Port Probe")
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
                        resultText(probeResult, empty: "Probe a single TCP host and port.")

                        Divider().background(AppTheme.hairline)
                        Text("Bounded Port Scan")
                            .font(.headline)
                        TextField("Ports, e.g. 22,80,443 or 8000-8010", text: $scanPorts)
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        Button {
                            Task { @MainActor in
                                scanResult = await services.network.scanPorts(host: probeHost, ports: scanPorts)
                                services.log("Port scan completed")
                            }
                        } label: {
                            Label("Scan Ports", systemImage: "dot.radiowaves.left.and.right")
                        }
                        .buttonStyle(.bordered)
                        resultText(scanResult, empty: "Scans are limited to 32 ports per run.")
                    }
                }

                SectionLabel(title: "Bonjour / mDNS")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            TextField("Service type", text: $bonjourType)
                                .textInputAutocapitalization(.never)
                                .padding(10)
                                .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                            Button("Browse") {
                                services.network.startBonjourBrowse(type: bonjourType)
                                services.log("Bonjour browse started")
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Stop") {
                                services.network.stopBonjourBrowse()
                            }
                            .buttonStyle(.bordered)
                        }
                        Text(services.network.bonjourStatus)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        if services.network.bonjourServices.isEmpty {
                            Text("Discovered local services will appear here.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        } else {
                            ForEach(services.network.bonjourServices) { service in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(service.name)
                                    Text("\(service.hostName):\(service.port)  \(service.type)")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Divider().background(AppTheme.hairline)
                            }
                        }
                    }
                }

                SectionLabel(title: "Wake-on-LAN")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("MAC address", text: $wolMac)
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        Button {
                            Task { @MainActor in
                                wolResult = await services.network.sendWakeOnLAN(macAddress: wolMac)
                                services.log("Wake-on-LAN packet requested")
                            }
                        } label: {
                            Label("Send Magic Packet", systemImage: "power")
                        }
                        .buttonStyle(.bordered)
                        resultText(wolResult, empty: "Sends a UDP magic packet to the local broadcast address.")
                    }
                }

                if !services.network.history.isEmpty {
                    SectionLabel(title: "Network History")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(services.network.history.prefix(8)) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.title)
                                            .font(.caption.weight(.semibold))
                                        Spacer()
                                        Text("\(item.durationMilliseconds) ms")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.tertiaryText)
                                    }
                                    Text(item.response)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .lineLimit(2)
                                }
                                Divider().background(AppTheme.hairline)
                            }
                            Button("Clear Network History") {
                                services.network.clearHistory()
                            }
                            .buttonStyle(.bordered)
                        }
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

    private func resultText(_ text: String, empty: String) -> some View {
        Text(text.isEmpty ? empty : text)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(text.isEmpty ? AppTheme.secondaryText : AppTheme.primaryText)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }
}
