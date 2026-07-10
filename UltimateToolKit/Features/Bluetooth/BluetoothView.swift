import SwiftUI

struct BluetoothView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var mode: TerminalMode = .ascii
    @State private var terminalInput = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    VStack(spacing: 14) {
                        HStack {
                            Label("Bluetooth", systemImage: "bolt.horizontal.circle.fill")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(services.bluetooth.stateDescription)
                                .foregroundStyle(services.bluetooth.stateDescription == "On" ? .green : .orange)
                        }
                        HStack {
                            Text(services.bluetooth.isScanning ? "Scanning for BLE peripherals..." : "Scanner idle")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            if services.bluetooth.isScanning {
                                ProgressView()
                            }
                        }
                        if let error = services.bluetooth.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                HStack {
                    Button(services.bluetooth.isScanning ? "Stop Scan" : "Start Scan") {
                        if services.bluetooth.isScanning {
                            services.bluetooth.stopScan()
                            services.log("BLE scan stopped")
                        } else {
                            services.bluetooth.startScan()
                            services.log("BLE scan started")
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if services.bluetooth.connectedDevice != nil {
                        Button("Disconnect") {
                            services.bluetooth.disconnect()
                            services.log("BLE disconnect requested")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                SectionLabel(title: "Available Devices")
                GlassPanel {
                    VStack(spacing: 0) {
                        if services.bluetooth.devices.isEmpty {
                            emptyState("No peripherals discovered yet. Start a scan near a BLE device.")
                        } else {
                            ForEach(services.bluetooth.devices) { device in
                                Button {
                                    services.bluetooth.connect(to: device)
                                    services.log("Connecting to \(device.name)")
                                } label: {
                                    deviceRow(device)
                                }
                                .buttonStyle(.plain)
                                Divider().background(AppTheme.hairline)
                            }
                        }
                    }
                }

                if let connected = services.bluetooth.connectedDevice {
                    SectionLabel(title: "Connected")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(connected.name)
                                .font(.headline)
                            Text(connected.address)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SectionLabel(title: "Services")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            if services.bluetooth.services.isEmpty {
                                emptyState("Discovering GATT services...")
                            } else {
                                ForEach(services.bluetooth.services) { service in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(service.uuid)
                                            .font(.system(.caption, design: .monospaced).weight(.semibold))
                                        ForEach(service.characteristics) { characteristic in
                                            characteristicRow(characteristic)
                                        }
                                    }
                                    Divider().background(AppTheme.hairline)
                                }
                            }
                        }
                    }
                }

                SectionLabel(title: "Terminal")
                TerminalSurface(lines: services.bluetooth.terminalLines)

                HStack {
                    TextField("Type a message", text: $terminalInput)
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                    Button("Send") {
                        services.bluetooth.write(terminalInput, mode: mode)
                        services.log("BLE terminal send requested in \(mode.rawValue)")
                        terminalInput = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(terminalInput.isEmpty || services.bluetooth.connectedDevice == nil)
                }

                Picker("Terminal Mode", selection: $mode) {
                    ForEach(TerminalMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
        }
        .navigationTitle("Bluetooth")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { services.log("Bluetooth options opened") } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .toolkitScreen()
    }

    private func deviceRow(_ device: BLEDevice) -> some View {
        HStack(spacing: 12) {
            Image(systemName: device.isConnected ? "checkmark.circle.fill" : "sensor.tag.radiowaves.forward")
                .foregroundStyle(device.isConnected ? .green : .blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .foregroundStyle(AppTheme.primaryText)
                Text(device.address)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(device.advertisement)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(device.rssi) dBm")
                .font(.caption)
                .foregroundStyle(device.rssi > -60 ? .green : AppTheme.secondaryText)
        }
        .padding(.vertical, 10)
    }

    private func characteristicRow(_ characteristic: BLECharacteristicInfo) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(characteristic.uuid)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text(characteristic.properties.joined(separator: " "))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            if !characteristic.valuePreview.isEmpty {
                Text(characteristic.valuePreview)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }
            HStack {
                if characteristic.properties.contains("read") {
                    Button("Read") { services.bluetooth.read(characteristic) }
                        .buttonStyle(.bordered)
                }
                if characteristic.properties.contains("notify") || characteristic.properties.contains("indicate") {
                    Button("Notify") { services.bluetooth.toggleNotify(characteristic) }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(10)
        .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
    }
}
