import AVFoundation
import Combine
import CoreBluetooth
import CoreMotion
import CryptoKit
import Foundation
import Network
import SwiftUI
import UIKit

#if canImport(CoreNFC)
import CoreNFC
#endif

#if canImport(Darwin)
import Darwin
#endif

@MainActor
final class ToolkitServices: ObservableObject {
    @Published private(set) var logs: [LogEntry] = []

    let sensors = SensorService()
    let bluetooth = BluetoothService()
    let network = NetworkService()
    let nfc = NFCService()
    let automations = AutomationService()
    let audio = AudioService()
    let utilities = DeveloperUtilityService()

    func log(_ message: String, level: LogEntry.Level = .info) {
        logs.insert(LogEntry(date: Date(), level: level, message: message), at: 0)
        logs = Array(logs.prefix(120))
    }
}

enum AppPersistence {
    static func load<T: Decodable>(_ type: T.Type, key: String, fallback: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode(type, from: data) else {
            return fallback
        }
        return value
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

@MainActor
final class SensorService: ObservableObject {
    @Published private(set) var metrics: [SensorMetric] = []
    @Published private(set) var lastUpdated = Date()

    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var history: [String: [Double]] = [:]

    func start() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        if motionManager.isAccelerometerAvailable && !motionManager.isAccelerometerActive {
            motionManager.accelerometerUpdateInterval = 0.25
            motionManager.startAccelerometerUpdates()
        }

        if motionManager.isGyroAvailable && !motionManager.isGyroActive {
            motionManager.gyroUpdateInterval = 0.25
            motionManager.startGyroUpdates()
        }

        update()
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }

    func exportCSV() -> String {
        var rows = ["metric,value,detail,updated"]
        for metric in metrics {
            rows.append("\"\(metric.title)\",\"\(metric.value)\",\"\(metric.detail)\",\"\(ISO8601DateFormatter().string(from: lastUpdated))\"")
        }
        return rows.joined(separator: "\n")
    }

    private func update() {
        lastUpdated = Date()

        let batteryLevel = UIDevice.current.batteryLevel
        let batteryPercent = batteryLevel >= 0 ? Int(batteryLevel * 100) : nil
        let batteryState = Self.batteryStateDescription(UIDevice.current.batteryState)
        let thermal = Self.thermalDescription(ProcessInfo.processInfo.thermalState)
        let brightness = Int(UIScreen.main.brightness * 100)
        let fps = UIScreen.main.maximumFramesPerSecond
        let storage = Self.availableStorageDescription()
        let memory = ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory)
        let acceleration = motionManager.accelerometerData?.acceleration
        let gyro = motionManager.gyroData?.rotationRate

        metrics = [
            SensorMetric(
                title: "Accelerometer",
                detail: acceleration.map { String(format: "X: %.2f  Y: %.2f  Z: %.2f g", $0.x, $0.y, $0.z) } ?? "No accelerometer reading yet",
                value: acceleration == nil ? "Waiting" : "Live",
                symbol: "move.3d",
                tint: acceleration == nil ? .gray : .blue,
                trend: append("accelerometer", value: acceleration.map { sqrt($0.x * $0.x + $0.y * $0.y + $0.z * $0.z) })
            ),
            SensorMetric(
                title: "Gyroscope",
                detail: gyro.map { String(format: "X: %.2f  Y: %.2f  Z: %.2f rad/s", $0.x, $0.y, $0.z) } ?? "No gyroscope reading yet",
                value: gyro == nil ? "Waiting" : "Live",
                symbol: "gyroscope",
                tint: gyro == nil ? .gray : .purple,
                trend: append("gyroscope", value: gyro.map { sqrt($0.x * $0.x + $0.y * $0.y + $0.z * $0.z) })
            ),
            SensorMetric(
                title: "Battery",
                detail: batteryState,
                value: batteryPercent.map { "\($0)%" } ?? "Unavailable",
                symbol: "battery.100percent",
                tint: (batteryPercent ?? 100) < 20 ? .orange : .green,
                trend: append("battery", value: batteryPercent.map { Double($0) / 100 })
            ),
            SensorMetric(
                title: "Thermal State",
                detail: "ProcessInfo thermal monitor",
                value: thermal,
                symbol: "thermometer.medium",
                tint: ProcessInfo.processInfo.thermalState == .nominal ? .green : .orange,
                trend: append("thermal", value: Double(ProcessInfo.processInfo.thermalState.severityValue))
            ),
            SensorMetric(
                title: "Display",
                detail: "Brightness \(brightness)%  Max \(fps) Hz",
                value: "\(fps) Hz",
                symbol: "display",
                tint: .cyan,
                trend: append("display", value: Double(brightness) / 100)
            ),
            SensorMetric(
                title: "Memory",
                detail: "Physical memory \(memory)",
                value: memory,
                symbol: "memorychip",
                tint: .mint,
                trend: []
            ),
            SensorMetric(
                title: "Storage",
                detail: "Available app volume capacity",
                value: storage,
                symbol: "internaldrive",
                tint: .orange,
                trend: []
            ),
            SensorMetric(
                title: "Orientation",
                detail: UIDevice.current.orientation.description,
                value: UIDevice.current.orientation == .unknown ? "Unknown" : "Device",
                symbol: "iphone.gen3",
                tint: .indigo,
                trend: []
            )
        ]
    }

    private func append(_ key: String, value: Double?) -> [Double] {
        guard let value else { return history[key] ?? [] }
        var values = history[key] ?? []
        values.append(value)
        history[key] = Array(values.suffix(24))
        return history[key] ?? []
    }

    private static func batteryStateDescription(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: "Battery state unavailable"
        case .unplugged: "Running on battery"
        case .charging: "Charging"
        case .full: "Fully charged"
        @unknown default: "Battery state unknown"
        }
    }

    private static func thermalDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: "Nominal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        @unknown default: "Unknown"
        }
    }

    private static func availableStorageDescription() -> String {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        guard let capacity = values?.volumeAvailableCapacityForImportantUsage else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: capacity, countStyle: .file)
    }
}

extension ProcessInfo.ThermalState {
    var severityValue: Int {
        switch self {
        case .nominal: 0
        case .fair: 1
        case .serious: 2
        case .critical: 3
        @unknown default: 0
        }
    }
}

extension UIDeviceOrientation {
    var description: String {
        switch self {
        case .portrait: "Portrait"
        case .portraitUpsideDown: "Portrait upside down"
        case .landscapeLeft: "Landscape left"
        case .landscapeRight: "Landscape right"
        case .faceUp: "Face up"
        case .faceDown: "Face down"
        case .unknown: "Unknown"
        @unknown default: "Unknown"
        }
    }
}

final class BluetoothService: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published private(set) var stateDescription = "Initializing"
    @Published private(set) var devices: [BLEDevice] = []
    @Published private(set) var connectedDevice: BLEDevice?
    @Published private(set) var services: [BLEServiceInfo] = []
    @Published private(set) var terminalLines: [ConsoleLine] = []
    @Published private(set) var isScanning = false
    @Published private(set) var lastError: String?

    private var central: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var characteristics: [String: CBCharacteristic] = [:]
    private var writableCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard central?.state == .poweredOn else {
            lastError = "Bluetooth is \(stateDescription.lowercased())."
            return
        }
        devices.removeAll()
        services.removeAll()
        lastError = nil
        isScanning = true
        central?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func stopScan() {
        central?.stopScan()
        isScanning = false
    }

    func connect(to device: BLEDevice) {
        guard let peripheral = peripherals[device.id] else {
            lastError = "Peripheral reference expired. Scan again."
            return
        }
        stopScan()
        connectedDevice = device
        terminalLines = [ConsoleLine(direction: .system, text: "Connecting to \(device.name)...")]
        peripheral.delegate = self
        central?.connect(peripheral)
    }

    func disconnect() {
        guard let id = connectedDevice?.id, let peripheral = peripherals[id] else { return }
        central?.cancelPeripheralConnection(peripheral)
    }

    func read(_ characteristic: BLECharacteristicInfo) {
        guard let connected = connectedDevice,
              let peripheral = peripherals[connected.id],
              let cbCharacteristic = characteristics[characteristic.id] else { return }
        peripheral.readValue(for: cbCharacteristic)
    }

    func toggleNotify(_ characteristic: BLECharacteristicInfo) {
        guard let connected = connectedDevice,
              let peripheral = peripherals[connected.id],
              let cbCharacteristic = characteristics[characteristic.id] else { return }
        peripheral.setNotifyValue(!cbCharacteristic.isNotifying, for: cbCharacteristic)
    }

    func write(_ text: String, mode: TerminalMode) {
        guard let connected = connectedDevice,
              let peripheral = peripherals[connected.id],
              let characteristic = writableCharacteristic else {
            terminalLines.append(ConsoleLine(direction: .system, text: "No writable characteristic discovered."))
            return
        }
        guard let data = Self.encode(text, mode: mode) else {
            terminalLines.append(ConsoleLine(direction: .system, text: "Could not encode message as \(mode.rawValue)."))
            return
        }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
        terminalLines.append(ConsoleLine(direction: .outbound, text: text))
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: stateDescription = "On"
        case .poweredOff: stateDescription = "Off"
        case .resetting: stateDescription = "Resetting"
        case .unauthorized: stateDescription = "Unauthorized"
        case .unsupported: stateDescription = "Unsupported"
        case .unknown: stateDescription = "Unknown"
        @unknown default: stateDescription = "Unknown"
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        peripherals[peripheral.identifier] = peripheral
        let name = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? "Unnamed Peripheral"
        let summary = Self.advertisementSummary(advertisementData)
        let isConnected = connectedDevice?.id == peripheral.identifier
        let device = BLEDevice(
            id: peripheral.identifier,
            name: name,
            address: peripheral.identifier.uuidString,
            rssi: RSSI.intValue,
            advertisement: summary,
            lastSeen: Date(),
            isConnected: isConnected
        )

        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        devices.sort { $0.rssi > $1.rssi }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        terminalLines.append(ConsoleLine(direction: .system, text: "Connected. Discovering services..."))
        connectedDevice = devices.first(where: { $0.id == peripheral.identifier }) ?? connectedDevice
        peripheral.discoverServices(nil)
        updateConnectedState(peripheral.identifier, isConnected: true)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        lastError = error?.localizedDescription ?? "Failed to connect."
        terminalLines.append(ConsoleLine(direction: .system, text: lastError ?? "Connection failed."))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        terminalLines.append(ConsoleLine(direction: .system, text: error.map { "Disconnected: \($0.localizedDescription)" } ?? "Disconnected."))
        updateConnectedState(peripheral.identifier, isConnected: false)
        connectedDevice = nil
        services = []
        writableCharacteristic = nil
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            terminalLines.append(ConsoleLine(direction: .system, text: "Service discovery failed: \(error.localizedDescription)"))
            return
        }
        services = (peripheral.services ?? []).map {
            BLEServiceInfo(id: $0.uuid.uuidString, uuid: $0.uuid.uuidString, characteristics: [])
        }
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            terminalLines.append(ConsoleLine(direction: .system, text: "Characteristic discovery failed: \(error.localizedDescription)"))
            return
        }
        let infos = (service.characteristics ?? []).map { characteristic in
            let id = "\(service.uuid.uuidString):\(characteristic.uuid.uuidString)"
            characteristics[id] = characteristic
            if writableCharacteristic == nil,
               characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristic = characteristic
            }
            return BLECharacteristicInfo(
                id: id,
                uuid: characteristic.uuid.uuidString,
                properties: Self.properties(characteristic.properties),
                valuePreview: characteristic.value.map(Self.format) ?? ""
            )
        }
        if let index = services.firstIndex(where: { $0.id == service.uuid.uuidString }) {
            services[index].characteristics = infos
        }
        terminalLines.append(ConsoleLine(direction: .system, text: "Discovered \(infos.count) characteristic(s) for \(service.uuid.uuidString)."))
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let valueText = error.map { "Read failed: \($0.localizedDescription)" } ?? characteristic.value.map(Self.format) ?? "Empty value"
        terminalLines.append(ConsoleLine(direction: .inbound, text: valueText))
        updateCharacteristic(characteristic, value: valueText)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            terminalLines.append(ConsoleLine(direction: .system, text: "Write failed: \(error.localizedDescription)"))
        } else {
            terminalLines.append(ConsoleLine(direction: .system, text: "Write acknowledged."))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let message = error.map { "Notify failed: \($0.localizedDescription)" } ?? "Notifications \(characteristic.isNotifying ? "enabled" : "disabled") for \(characteristic.uuid.uuidString)."
        terminalLines.append(ConsoleLine(direction: .system, text: message))
    }

    private func updateConnectedState(_ id: UUID, isConnected: Bool) {
        if let index = devices.firstIndex(where: { $0.id == id }) {
            devices[index].isConnected = isConnected
            if isConnected {
                connectedDevice = devices[index]
            }
        }
    }

    private func updateCharacteristic(_ characteristic: CBCharacteristic, value: String) {
        for serviceIndex in services.indices {
            if let charIndex = services[serviceIndex].characteristics.firstIndex(where: { $0.uuid == characteristic.uuid.uuidString }) {
                services[serviceIndex].characteristics[charIndex].valuePreview = value
            }
        }
    }

    private static func advertisementSummary(_ advertisementData: [String: Any]) -> String {
        var parts: [String] = []
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], !serviceUUIDs.isEmpty {
            parts.append(serviceUUIDs.map(\.uuidString).joined(separator: ", "))
        }
        if let manufacturer = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            parts.append("MFG \(manufacturer.count) bytes")
        }
        return parts.isEmpty ? "Advertisement" : parts.joined(separator: " | ")
    }

    private static func properties(_ properties: CBCharacteristicProperties) -> [String] {
        var values: [String] = []
        if properties.contains(.read) { values.append("read") }
        if properties.contains(.write) { values.append("write") }
        if properties.contains(.writeWithoutResponse) { values.append("writeNoRsp") }
        if properties.contains(.notify) { values.append("notify") }
        if properties.contains(.indicate) { values.append("indicate") }
        return values
    }

    private static func format(_ data: Data) -> String {
        if let text = String(data: data, encoding: .utf8), text.rangeOfCharacter(from: .controlCharacters) == nil {
            return text
        }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    private static func encode(_ text: String, mode: TerminalMode) -> Data? {
        switch mode {
        case .ascii:
            return Data(text.utf8)
        case .hex:
            let hex = text.filter { $0.isHexDigit }
            guard hex.count.isMultiple(of: 2) else { return nil }
            var data = Data()
            var index = hex.startIndex
            while index < hex.endIndex {
                let next = hex.index(index, offsetBy: 2)
                guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
                data.append(byte)
                index = next
            }
            return data
        case .binary:
            let bits = text.filter { $0 == "0" || $0 == "1" }
            guard bits.count.isMultiple(of: 8) else { return nil }
            var data = Data()
            var index = bits.startIndex
            while index < bits.endIndex {
                let next = bits.index(index, offsetBy: 8)
                guard let byte = UInt8(bits[index..<next], radix: 2) else { return nil }
                data.append(byte)
                index = next
            }
            return data
        }
    }
}

final class NetworkService: ObservableObject {
    @Published private(set) var status = "Starting"
    @Published private(set) var isExpensive = false
    @Published private(set) var activeInterfaces: [String] = []
    @Published private(set) var ipAddresses: [String] = []

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ToolkitNetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.status = path.status == .satisfied ? "Online" : "Offline"
                self?.isExpensive = path.isExpensive
                self?.activeInterfaces = path.availableInterfaces.map(\.name)
                self?.ipAddresses = Self.localIPAddresses()
            }
        }
        monitor.start(queue: queue)
    }

    func refreshInterfaces() {
        ipAddresses = Self.localIPAddresses()
    }

    func httpGet(_ rawURL: String) async -> String {
        guard let url = URL(string: rawURL), ["http", "https"].contains(url.scheme?.lowercased()) else {
            return "Enter a valid http or https URL."
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "\(data.count) bytes"
            return "HTTP \(code)\n\n\(body)"
        } catch {
            return "Request failed: \(error.localizedDescription)"
        }
    }

    func tcpProbe(host: String, port: UInt16, timeout: TimeInterval = 3) async -> String {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty, let nwPort = NWEndpoint.Port(rawValue: port) else {
            return "Enter a host and valid port."
        }

        return await withCheckedContinuation { continuation in
            let connection = NWConnection(host: NWEndpoint.Host(trimmedHost), port: nwPort, using: .tcp)
            let lock = NSLock()
            var resumed = false

            func finish(_ result: String) {
                lock.lock()
                defer { lock.unlock() }
                guard !resumed else { return }
                resumed = true
                connection.cancel()
                continuation.resume(returning: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    finish("\(trimmedHost):\(port) is reachable.")
                case .failed(let error):
                    finish("\(trimmedHost):\(port) failed: \(error.localizedDescription)")
                case .waiting(let error):
                    finish("\(trimmedHost):\(port) waiting: \(error.localizedDescription)")
                default:
                    break
                }
            }
            connection.start(queue: DispatchQueue.global(qos: .utility))
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                finish("\(trimmedHost):\(port) timed out after \(Int(timeout))s.")
            }
        }
    }

    private static func localIPAddresses() -> [String] {
        #if canImport(Darwin)
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        for pointer in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            guard let addressPointer = interface.ifa_addr else { continue }
            let family = addressPointer.pointee.sa_family
            guard family == UInt8(AF_INET) || family == UInt8(AF_INET6) else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                addressPointer,
                socklen_t(addressPointer.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            if result == 0 {
                let name = String(cString: interface.ifa_name)
                let address = String(cString: hostname)
                if !address.hasPrefix("127.") && address != "::1" {
                    addresses.append("\(name): \(address)")
                }
            }
        }
        return addresses
        #else
        return []
        #endif
    }
}

final class NFCService: NSObject, ObservableObject {
    @Published private(set) var lastResult: NFCScanResult?
    @Published private(set) var history: [NFCScanResult] = AppPersistence.load([NFCScanResult].self, key: "nfc.history", fallback: [])
    @Published private(set) var status = "Ready"

    #if canImport(CoreNFC)
    private var session: NFCNDEFReaderSession?
    private var pendingWriteMessage: NFCNDEFMessage?
    #endif

    func beginRead() {
        #if canImport(CoreNFC)
        guard NFCNDEFReaderSession.readingAvailable else {
            status = "NFC reading is unavailable on this device."
            return
        }
        pendingWriteMessage = nil
        status = "Hold near an NFC tag."
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Scan an NDEF tag"
        session?.begin()
        #else
        status = "CoreNFC is unavailable in this build."
        #endif
    }

    func beginWrite(text: String) {
        #if canImport(CoreNFC)
        guard NFCNDEFReaderSession.readingAvailable else {
            status = "NFC writing is unavailable on this device."
            return
        }
        let payload: NFCNDEFPayload
        if let url = URL(string: text), url.scheme != nil {
            payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) ?? NFCNDEFPayload(format: .nfcWellKnown, type: Data([0x55]), identifier: Data(), payload: Data(text.utf8))
        } else {
            payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: Locale.current) ?? NFCNDEFPayload(format: .nfcWellKnown, type: Data([0x54]), identifier: Data(), payload: Data(text.utf8))
        }
        pendingWriteMessage = NFCNDEFMessage(records: [payload])
        status = "Hold near a writable NFC tag."
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold near a writable NDEF tag"
        session?.begin()
        #else
        status = "CoreNFC is unavailable in this build."
        #endif
    }

    func clearHistory() {
        history = []
        lastResult = nil
        AppPersistence.save(history, key: "nfc.history")
    }

    private func store(title: String, payload: String, detail: String) {
        let result = NFCScanResult(date: Date(), title: title, payload: payload, detail: detail)
        lastResult = result
        history.insert(result, at: 0)
        history = Array(history.prefix(100))
        AppPersistence.save(history, key: "nfc.history")
    }
}

#if canImport(CoreNFC)
extension NFCService: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.status = "Session ended: \(error.localizedDescription)"
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        let records = messages.flatMap(\.records)
        let payload = records.map(Self.describe).joined(separator: "\n")
        DispatchQueue.main.async {
            self.status = "Read \(records.count) record(s)."
            self.store(title: "NDEF Tag", payload: payload.isEmpty ? "Empty payload" : payload, detail: "\(records.count) record(s)")
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let pendingWriteMessage else { return }
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected.")
            return
        }
        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: error.localizedDescription)
                return
            }
            tag.queryNDEFStatus { status, capacity, error in
                if let error {
                    session.invalidate(errorMessage: error.localizedDescription)
                    return
                }
                guard status == .readWrite else {
                    session.invalidate(errorMessage: "Tag is not writable.")
                    return
                }
                guard pendingWriteMessage.length <= capacity else {
                    session.invalidate(errorMessage: "Payload is larger than tag capacity.")
                    return
                }
                tag.writeNDEF(pendingWriteMessage) { error in
                    if let error {
                        session.invalidate(errorMessage: error.localizedDescription)
                    } else {
                        session.alertMessage = "Tag written."
                        session.invalidate()
                        DispatchQueue.main.async {
                            self.status = "Write complete."
                            self.store(title: "Written NDEF Tag", payload: "\(pendingWriteMessage.records.count) record(s)", detail: "Write successful")
                        }
                    }
                }
            }
        }
    }

    private static func describe(_ record: NFCNDEFPayload) -> String {
        if let text = record.wellKnownTypeTextPayload().0 {
            return "Text: \(text)"
        }
        if let url = record.wellKnownTypeURIPayload() {
            return "URL: \(url.absoluteString)"
        }
        if let raw = String(data: record.payload, encoding: .utf8), !raw.isEmpty {
            return raw
        }
        return record.payload.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
#endif

@MainActor
final class AutomationService: ObservableObject {
    @Published private(set) var rules: [AutomationRule] = AppPersistence.load([AutomationRule].self, key: "automation.rules", fallback: [])
    @Published private(set) var executionLog: [String] = []

    func add(title: String, trigger: String, action: String, symbol: String = "gearshape.2.fill", tintKey: String = "purple") {
        let rule = AutomationRule(
            title: title.isEmpty ? "Untitled Automation" : title,
            trigger: trigger.isEmpty ? "Manual trigger" : trigger,
            action: action.isEmpty ? "Log event" : action,
            symbol: symbol,
            tintKey: tintKey,
            isEnabled: true
        )
        rules.insert(rule, at: 0)
        persist()
    }

    func setEnabled(_ rule: AutomationRule, enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index].isEnabled = enabled
        persist()
    }

    func run(_ rule: AutomationRule) {
        executionLog.insert("\(Date().formatted(date: .abbreviated, time: .standard)): \(rule.title) -> \(rule.action)", at: 0)
        executionLog = Array(executionLog.prefix(80))
    }

    func delete(_ rule: AutomationRule) {
        rules.removeAll { $0.id == rule.id }
        persist()
    }

    private func persist() {
        AppPersistence.save(rules, key: "automation.rules")
    }
}

@MainActor
final class AudioService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var levels: [Double] = []
    @Published private(set) var isMonitoring = false
    @Published private(set) var permissionStatus = "Not requested"
    @Published private(set) var routeDescription = "Default"

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func refreshRoute() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs.map(\.portName)
        routeDescription = outputs.isEmpty ? "Default" : outputs.joined(separator: ", ")
    }

    func requestPermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    self?.permissionStatus = granted ? "Granted" : "Denied"
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    self?.permissionStatus = granted ? "Granted" : "Denied"
                }
            }
        }
    }

    func startMetering() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ToolkitAudioMeter.caf")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatAppleIMA4),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.delegate = self
            recorder?.record()
            isMonitoring = true
            refreshRoute()
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.updateMeter()
                }
            }
        } catch {
            permissionStatus = "Audio start failed: \(error.localizedDescription)"
        }
    }

    func stopMetering() {
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func updateMeter() {
        recorder?.updateMeters()
        let power = recorder?.averagePower(forChannel: 0) ?? -80
        let normalized = max(0, min(1, (Double(power) + 80) / 80))
        levels.append(normalized)
        levels = Array(levels.suffix(64))
    }
}

struct DeveloperUtilityService {
    func run(_ tool: DeveloperToolKind, input: String, pattern: String = "") -> String {
        do {
            switch tool {
            case .formatJSON:
                return try formatJSON(input)
            case .minifyJSON:
                return try minifyJSON(input)
            case .base64Encode:
                return Data(input.utf8).base64EncodedString()
            case .base64Decode:
                guard let data = Data(base64Encoded: input) else { return "Invalid Base64 input." }
                return String(decoding: data, as: UTF8.self)
            case .sha256:
                return SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
            case .urlEncode:
                return input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            case .urlDecode:
                return input.removingPercentEncoding ?? input
            case .uuid:
                return UUID().uuidString
            case .jwtDecode:
                return decodeJWT(input)
            case .regex:
                return try regexMatches(pattern: pattern, text: input)
            case .colorHexToRGB:
                return try hexToRGB(input)
            case .timestamp:
                return timestamp(input)
            }
        } catch {
            return error.localizedDescription
        }
    }

    func formatJSON(_ text: String) throws -> String {
        let data = Data(text.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        let pretty = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        return String(decoding: pretty, as: UTF8.self)
    }

    func minifyJSON(_ text: String) throws -> String {
        let data = Data(text.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        let minified = try JSONSerialization.data(withJSONObject: object)
        return String(decoding: minified, as: UTF8.self)
    }

    private func decodeJWT(_ token: String) -> String {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return "JWT must contain at least header and payload." }
        return parts.prefix(2).enumerated().map { index, part in
            let label = index == 0 ? "Header" : "Payload"
            let decoded = decodeBase64URL(String(part))
            if let data = decoded.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) {
                return "\(label):\n\(String(decoding: pretty, as: UTF8.self))"
            }
            return "\(label):\n\(decoded)"
        }.joined(separator: "\n\n")
    }

    private func decodeBase64URL(_ value: String) -> String {
        var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let data = Data(base64Encoded: base64) else { return "Invalid Base64URL segment." }
        return String(decoding: data, as: UTF8.self)
    }

    private func regexMatches(pattern: String, text: String) throws -> String {
        guard !pattern.isEmpty else { return "Enter a regex pattern." }
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)
        guard !matches.isEmpty else { return "No matches." }
        return matches.enumerated().map { index, match in
            let captures = (0..<match.numberOfRanges).compactMap { group -> String? in
                let matchRange = match.range(at: group)
                guard let range = Range(matchRange, in: text) else { return nil }
                return "\(group): \(text[range])"
            }.joined(separator: "\n")
            return "Match \(index + 1):\n\(captures)"
        }.joined(separator: "\n\n")
    }

    private func hexToRGB(_ input: String) throws -> String {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
            throw NSError(domain: "DeveloperUtilityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Enter a 6-digit hex color."])
        }
        let red = (value >> 16) & 0xFF
        let green = (value >> 8) & 0xFF
        let blue = value & 0xFF
        return "RGB(\(red), \(green), \(blue))\nSwiftUI Color(red: \(red)/255, green: \(green)/255, blue: \(blue)/255)"
    }

    private func timestamp(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let seconds = TimeInterval(trimmed) {
            return Date(timeIntervalSince1970: seconds).formatted(date: .complete, time: .complete)
        }
        return "\(Int(Date().timeIntervalSince1970))"
    }
}
