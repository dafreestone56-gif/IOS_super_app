import AVFoundation
import Combine
import CoreBluetooth
import CoreLocation
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
final class SensorService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var metrics: [SensorMetric] = []
    @Published private(set) var lastUpdated = Date()
    @Published private(set) var locationAuthorization = "Not requested"
    @Published private(set) var isLogging = false
    @Published private(set) var loggingStartedAt: Date?
    @Published private(set) var loggedSamples: [SensorLogSample] = AppPersistence.load([SensorLogSample].self, key: "sensor.loggedSamples", fallback: [])

    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var history: [String: [Double]] = [:]
    private var pressureKilopascals: Double?
    private var relativeAltitudeMeters: Double?
    private var latestLocation: CLLocation?
    private var latestHeading: CLHeading?
    private var loggingPersistenceCounter = 0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 3
        locationAuthorization = Self.authorizationDescription(locationManager.authorizationStatus)
    }

    func refreshSnapshot() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        update()
    }

    func start() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        UIDevice.current.isProximityMonitoringEnabled = true

        if motionManager.isAccelerometerAvailable && !motionManager.isAccelerometerActive {
            motionManager.accelerometerUpdateInterval = 0.25
            motionManager.startAccelerometerUpdates()
        }

        if motionManager.isGyroAvailable && !motionManager.isGyroActive {
            motionManager.gyroUpdateInterval = 0.25
            motionManager.startGyroUpdates()
        }

        if motionManager.isMagnetometerAvailable && !motionManager.isMagnetometerActive {
            motionManager.magnetometerUpdateInterval = 0.25
            motionManager.startMagnetometerUpdates()
        }

        if motionManager.isDeviceMotionAvailable && !motionManager.isDeviceMotionActive {
            motionManager.deviceMotionUpdateInterval = 0.25
            motionManager.startDeviceMotionUpdates()
        }

        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let data else { return }
                Task { @MainActor in
                    self?.pressureKilopascals = data.pressure.doubleValue
                    self?.relativeAltitudeMeters = data.relativeAltitude.doubleValue
                }
            }
        }

        startLocationStreamsIfAuthorized()
        update()
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
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
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        UIDevice.current.isProximityMonitoringEnabled = false
    }

    func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startLogging() {
        start()
        loggedSamples.removeAll()
        loggingStartedAt = Date()
        isLogging = true
        loggingPersistenceCounter = 0
        AppPersistence.save(loggedSamples, key: "sensor.loggedSamples")
    }

    func stopLogging() {
        isLogging = false
        AppPersistence.save(loggedSamples, key: "sensor.loggedSamples")
    }

    func clearLoggedSamples() {
        isLogging = false
        loggingStartedAt = nil
        loggedSamples.removeAll()
        AppPersistence.save(loggedSamples, key: "sensor.loggedSamples")
    }

    func samples(for sensor: String) -> [SensorLogSample] {
        loggedSamples.filter { $0.sensor == sensor }
    }

    func exportLoggedCSV() -> String {
        var rows = ["date,sensor,value,detail"]
        let formatter = ISO8601DateFormatter()
        for sample in loggedSamples {
            rows.append("\"\(formatter.string(from: sample.date))\",\"\(sample.sensor)\",\"\(String(format: "%.6f", sample.value))\",\"\(sample.detail.replacingOccurrences(of: "\"", with: "\"\""))\"")
        }
        return rows.joined(separator: "\n")
    }

    func exportCSV() -> String {
        var rows = ["metric,value,detail,updated"]
        for metric in metrics {
            rows.append("\"\(metric.title)\",\"\(metric.value)\",\"\(metric.detail)\",\"\(ISO8601DateFormatter().string(from: lastUpdated))\"")
        }
        return rows.joined(separator: "\n")
    }

    func exportJSON() -> String {
        let snapshot = metrics.map { metric in
            [
                "title": metric.title,
                "value": metric.value,
                "detail": metric.detail,
                "updated": ISO8601DateFormatter().string(from: lastUpdated)
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: snapshot, options: [.prettyPrinted, .sortedKeys]) else {
            return "[]"
        }
        return String(decoding: data, as: UTF8.self)
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
        let magnetometer = motionManager.magnetometerData?.magneticField
        let attitude = motionManager.deviceMotion?.attitude
        let altitude = relativeAltitudeMeters
        let pressure = pressureKilopascals
        let heading = latestHeading
        let location = latestLocation

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
                title: "Magnetometer",
                detail: magnetometer.map { String(format: "X: %.1f  Y: %.1f  Z: %.1f uT", $0.x, $0.y, $0.z) } ?? "No magnetometer reading yet",
                value: magnetometer == nil ? "Waiting" : "Live",
                symbol: "safari",
                tint: magnetometer == nil ? .gray : .green,
                trend: append("magnetometer", value: magnetometer.map { sqrt($0.x * $0.x + $0.y * $0.y + $0.z * $0.z) })
            ),
            SensorMetric(
                title: "Device Motion",
                detail: attitude.map { String(format: "Pitch %.1f  Roll %.1f  Yaw %.1f deg", $0.pitch.degrees, $0.roll.degrees, $0.yaw.degrees) } ?? "No fused motion reading yet",
                value: attitude == nil ? "Waiting" : "Fused",
                symbol: "rotate.3d",
                tint: attitude == nil ? .gray : .blue,
                trend: append("deviceMotion", value: attitude.map { abs($0.pitch) + abs($0.roll) + abs($0.yaw) })
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
                title: "Barometer",
                detail: pressure.map { String(format: "%.2f kPa  Relative altitude %@", $0, altitude.map { String(format: "%.2f m", $0) } ?? "unknown") } ?? "Barometer unavailable or warming up",
                value: pressure.map { String(format: "%.2f kPa", $0) } ?? "Unavailable",
                symbol: "barometer",
                tint: pressure == nil ? .gray : .mint,
                trend: append("barometer", value: pressure)
            ),
            SensorMetric(
                title: "Heading",
                detail: heading.map { String(format: "Magnetic %.0f deg  True %.0f deg", $0.magneticHeading, $0.trueHeading) } ?? "Location permission required for heading",
                value: heading.map { String(format: "%.0f deg", $0.magneticHeading) } ?? locationAuthorization,
                symbol: "location.north.line.fill",
                tint: heading == nil ? .gray : .cyan,
                trend: append("heading", value: heading?.magneticHeading)
            ),
            SensorMetric(
                title: "Location",
                detail: location.map { String(format: "Lat %.5f  Lon %.5f  Accuracy %.0f m", $0.coordinate.latitude, $0.coordinate.longitude, $0.horizontalAccuracy) } ?? "Location permission required",
                value: location.map { String(format: "%.0f m", $0.horizontalAccuracy) } ?? locationAuthorization,
                symbol: "location.circle.fill",
                tint: location == nil ? .gray : .green,
                trend: append("locationAccuracy", value: location?.horizontalAccuracy)
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
                title: "Proximity",
                detail: UIDevice.current.isProximityMonitoringEnabled ? "Proximity monitor enabled" : "Proximity monitor unavailable",
                value: UIDevice.current.proximityState ? "Near" : "Far",
                symbol: "sensor",
                tint: UIDevice.current.proximityState ? .orange : .green,
                trend: append("proximity", value: UIDevice.current.proximityState ? 1 : 0)
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

        appendLogSamplesIfNeeded()
    }

    private func append(_ key: String, value: Double?) -> [Double] {
        guard let value else { return history[key] ?? [] }
        guard value.isFinite else { return history[key] ?? [] }
        var values = history[key] ?? []
        values.append(value)
        history[key] = Array(values.suffix(180))
        return history[key] ?? []
    }

    private func appendLogSamplesIfNeeded() {
        guard isLogging else { return }
        let date = Date()
        let samples = metrics.compactMap { metric -> SensorLogSample? in
            guard let value = metric.trend.last else { return nil }
            guard value.isFinite else { return nil }
            return SensorLogSample(date: date, sensor: metric.title, value: value, detail: metric.detail)
        }
        guard !samples.isEmpty else { return }
        loggedSamples.append(contentsOf: samples)
        loggedSamples = Array(loggedSamples.suffix(50_000))
        loggingPersistenceCounter += 1
        if loggingPersistenceCounter % 5 == 0 {
            AppPersistence.save(loggedSamples, key: "sensor.loggedSamples")
        }
    }

    private func startLocationStreamsIfAuthorized() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
        default:
            break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            locationAuthorization = Self.authorizationDescription(manager.authorizationStatus)
            startLocationStreamsIfAuthorized()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            latestLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            latestHeading = newHeading
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationAuthorization = "Location error: \(error.localizedDescription)"
        }
    }

    private static func batteryStateDescription(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "Battery state unavailable"
        case .unplugged: return "Running on battery"
        case .charging: return "Charging"
        case .full: return "Fully charged"
        @unknown default: return "Battery state unknown"
        }
    }

    private static func thermalDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private static func availableStorageDescription() -> String {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        guard let capacity = values?.volumeAvailableCapacityForImportantUsage else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: capacity, countStyle: .file)
    }

    private static func authorizationDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not requested"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When in use"
        @unknown default: return "Unknown"
        }
    }
}

extension Double {
    var degrees: Double { self * 180 / .pi }
}

extension ProcessInfo.ThermalState {
    var severityValue: Int {
        switch self {
        case .nominal: return 0
        case .fair: return 1
        case .serious: return 2
        case .critical: return 3
        @unknown default: return 0
        }
    }
}

extension UIDeviceOrientation {
    var description: String {
        switch self {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "Portrait upside down"
        case .landscapeLeft: return "Landscape left"
        case .landscapeRight: return "Landscape right"
        case .faceUp: return "Face up"
        case .faceDown: return "Face down"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
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
    @Published private(set) var savedDeviceIDs: [UUID] = AppPersistence.load([UUID].self, key: "ble.savedDeviceIDs", fallback: [])

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

    func toggleSaved(_ device: BLEDevice) {
        if savedDeviceIDs.contains(device.id) {
            savedDeviceIDs.removeAll { $0 == device.id }
        } else {
            savedDeviceIDs.append(device.id)
        }
        AppPersistence.save(savedDeviceIDs, key: "ble.savedDeviceIDs")
    }

    func isSaved(_ device: BLEDevice) -> Bool {
        savedDeviceIDs.contains(device.id)
    }

    func exportTerminalLog() -> String {
        terminalLines.map { "\($0.direction.rawValue) \($0.text)" }.joined(separator: "\n")
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

private final class TCPProbeCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false
    private let connection: NWConnection
    private let continuation: CheckedContinuation<String, Never>

    init(connection: NWConnection, continuation: CheckedContinuation<String, Never>) {
        self.connection = connection
        self.continuation = continuation
    }

    func finish(_ result: String) {
        lock.lock()
        let shouldResume = !didResume
        didResume = true
        lock.unlock()

        guard shouldResume else { return }
        connection.cancel()
        continuation.resume(returning: result)
    }
}

final class NetworkService: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {
    @Published private(set) var status = "Starting"
    @Published private(set) var isExpensive = false
    @Published private(set) var activeInterfaces: [String] = []
    @Published private(set) var ipAddresses: [String] = []
    @Published private(set) var history: [NetworkHistoryItem] = AppPersistence.load([NetworkHistoryItem].self, key: "network.history", fallback: [])
    @Published private(set) var bonjourServices: [BonjourServiceInfo] = []
    @Published private(set) var bonjourStatus = "Idle"

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ToolkitNetworkMonitor")
    private var browser: NetServiceBrowser?
    private var resolvingServices: [String: NetService] = [:]

    override init() {
        super.init()
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
        await httpRequest(url: rawURL, method: "GET", headers: "", body: "")
    }

    func httpRequest(url rawURL: String, method: String, headers rawHeaders: String, body: String) async -> String {
        guard let url = URL(string: rawURL), ["http", "https"].contains(url.scheme?.lowercased()) else {
            return "Enter a valid http or https URL."
        }
        let start = Date()
        do {
            var request = URLRequest(url: url, timeoutInterval: 30)
            request.httpMethod = method.uppercased()
            for header in Self.parseHeaders(rawHeaders) {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
            if !body.isEmpty, !["GET", "HEAD"].contains(request.httpMethod ?? "GET") {
                request.httpBody = Data(body.utf8)
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "\(data.count) bytes"
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)
            let result = "HTTP \(code)  \(elapsed) ms\n\n\(body)"
            let requestMethod = request.httpMethod ?? method.uppercased()
            let historyTitle = "\(requestMethod) \(url.host ?? rawURL)"
            await MainActor.run {
                recordHistory(title: historyTitle, request: rawURL, response: result, duration: elapsed)
            }
            return result
        } catch {
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)
            let result = "Request failed after \(elapsed) ms: \(error.localizedDescription)"
            await MainActor.run {
                recordHistory(title: "HTTP failed", request: rawURL, response: result, duration: elapsed)
            }
            return result
        }
    }

    func dnsLookup(host: String) async -> String {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Enter a host name." }

        return await Task.detached(priority: .utility) {
            #if canImport(Darwin)
            var hints = addrinfo(
                ai_flags: AI_ADDRCONFIG,
                ai_family: AF_UNSPEC,
                ai_socktype: SOCK_STREAM,
                ai_protocol: 0,
                ai_addrlen: 0,
                ai_canonname: nil,
                ai_addr: nil,
                ai_next: nil
            )
            var infoPointer: UnsafeMutablePointer<addrinfo>?
            let code = getaddrinfo(trimmed, nil, &hints, &infoPointer)
            guard code == 0, let first = infoPointer else {
                return "DNS lookup failed: \(String(cString: gai_strerror(code)))"
            }
            defer { freeaddrinfo(infoPointer) }

            var addresses: [String] = []
            for pointer in sequence(first: first, next: { $0.pointee.ai_next }) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(
                    pointer.pointee.ai_addr,
                    pointer.pointee.ai_addrlen,
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
                if result == 0 {
                    addresses.append(String(cString: hostname))
                }
            }
            let unique = Array(Set(addresses)).sorted()
            return unique.isEmpty ? "No DNS addresses returned." : unique.joined(separator: "\n")
            #else
            return "DNS lookup is unavailable in this build."
            #endif
        }.value
    }

    func scanPorts(host: String, ports rawPorts: String) async -> String {
        let ports = Self.parsePorts(rawPorts)
        guard !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "Enter a host." }
        guard !ports.isEmpty else { return "Enter ports like 22,80,443 or 8000-8010." }
        let limitedPorts = Array(ports.prefix(32))
        var rows: [String] = []
        for port in limitedPorts {
            let result = await tcpProbe(host: host, port: port, timeout: 1.25)
            rows.append(result)
        }
        if ports.count > limitedPorts.count {
            rows.append("Stopped at 32 ports to keep scans polite and battery-safe.")
        }
        return rows.joined(separator: "\n")
    }

    func startBonjourBrowse(type rawType: String) {
        let type = Self.normalizedBonjourType(rawType)
        stopBonjourBrowse()
        bonjourServices = []
        bonjourStatus = "Browsing \(type)"
        let browser = NetServiceBrowser()
        browser.delegate = self
        self.browser = browser
        browser.searchForServices(ofType: type, inDomain: "local.")
    }

    func stopBonjourBrowse() {
        browser?.stop()
        browser = nil
        resolvingServices.removeAll()
        bonjourStatus = "Idle"
    }

    func sendWakeOnLAN(macAddress: String, broadcastHost: String = "255.255.255.255", port: UInt16 = 9) async -> String {
        guard let packet = Self.magicPacket(macAddress: macAddress),
              let nwPort = NWEndpoint.Port(rawValue: port) else {
            return "Enter a valid MAC address like AA:BB:CC:DD:EE:FF."
        }

        return await withCheckedContinuation { continuation in
            let connection = NWConnection(host: NWEndpoint.Host(broadcastHost), port: nwPort, using: .udp)
            connection.stateUpdateHandler = { state in
                if case .ready = state {
                    connection.send(content: packet, completion: .contentProcessed { error in
                        connection.cancel()
                        if let error {
                            continuation.resume(returning: "Wake-on-LAN send failed: \(error.localizedDescription)")
                        } else {
                            continuation.resume(returning: "Wake-on-LAN packet sent to \(broadcastHost):\(port).")
                        }
                    })
                } else if case .failed(let error) = state {
                    connection.cancel()
                    continuation.resume(returning: "Wake-on-LAN connection failed: \(error.localizedDescription)")
                }
            }
            connection.start(queue: DispatchQueue.global(qos: .utility))
        }
    }

    func tcpProbe(host: String, port: UInt16, timeout: TimeInterval = 3) async -> String {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty, let nwPort = NWEndpoint.Port(rawValue: port) else {
            return "Enter a host and valid port."
        }

        return await withCheckedContinuation { continuation in
            let connection = NWConnection(host: NWEndpoint.Host(trimmedHost), port: nwPort, using: .tcp)
            let completion = TCPProbeCompletion(connection: connection, continuation: continuation)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    completion.finish("\(trimmedHost):\(port) is reachable.")
                case .failed(let error):
                    completion.finish("\(trimmedHost):\(port) failed: \(error.localizedDescription)")
                case .waiting(let error):
                    completion.finish("\(trimmedHost):\(port) waiting: \(error.localizedDescription)")
                default:
                    break
                }
            }
            connection.start(queue: DispatchQueue.global(qos: .utility))
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                completion.finish("\(trimmedHost):\(port) timed out after \(Int(timeout))s.")
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
            let length: socklen_t
            if family == UInt8(AF_INET) {
                length = socklen_t(MemoryLayout<sockaddr_in>.size)
            } else {
                length = socklen_t(MemoryLayout<sockaddr_in6>.size)
            }
            let result = getnameinfo(
                addressPointer,
                length,
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

    @MainActor
    private func recordHistory(title: String, request: String, response: String, duration: Int) {
        history.insert(NetworkHistoryItem(date: Date(), title: title, request: request, response: response, durationMilliseconds: duration), at: 0)
        history = Array(history.prefix(50))
        AppPersistence.save(history, key: "network.history")
    }

    func clearHistory() {
        history = []
        AppPersistence.save(history, key: "network.history")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        resolvingServices[service.name] = service
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        DispatchQueue.main.async {
            self.bonjourStatus = "Browse failed: \(errorDict)"
        }
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        let info = BonjourServiceInfo(
            name: sender.name,
            type: sender.type,
            domain: sender.domain,
            hostName: sender.hostName ?? "Unknown host",
            port: sender.port
        )
        DispatchQueue.main.async {
            if let index = self.bonjourServices.firstIndex(where: { $0.id == info.id }) {
                self.bonjourServices[index] = info
            } else {
                self.bonjourServices.append(info)
            }
            self.bonjourServices.sort { $0.name < $1.name }
            self.bonjourStatus = "Found \(self.bonjourServices.count) service(s)"
        }
    }

    private static func parseHeaders(_ raw: String) -> [(key: String, value: String)] {
        raw.split(whereSeparator: \.isNewline).compactMap { line in
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            return (parts[0].trimmingCharacters(in: .whitespaces), parts[1].trimmingCharacters(in: .whitespaces))
        }
    }

    private static func parsePorts(_ raw: String) -> [UInt16] {
        var ports: Set<UInt16> = []
        for part in raw.split(separator: ",") {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if let dash = trimmed.firstIndex(of: "-") {
                let startText = trimmed[..<dash]
                let endText = trimmed[trimmed.index(after: dash)...]
                if let start = UInt16(String(startText)), let end = UInt16(String(endText)), start <= end {
                    for port in start...end {
                        ports.insert(port)
                    }
                }
            } else if let port = UInt16(trimmed) {
                ports.insert(port)
            }
        }
        return ports.sorted()
    }

    private static func normalizedBonjourType(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "_http._tcp." }
        if trimmed.hasSuffix(".") { return trimmed }
        return "\(trimmed)."
    }

    private static func magicPacket(macAddress: String) -> Data? {
        let hex = macAddress.filter { $0.isHexDigit }
        guard hex.count == 12 else { return nil }
        var bytes: [UInt8] = []
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        var packet = Data(repeating: 0xFF, count: 6)
        for _ in 0..<16 {
            packet.append(contentsOf: bytes)
        }
        return packet
    }
}

final class NFCService: NSObject, ObservableObject {
    @Published private(set) var lastResult: NFCScanResult?
    @Published private(set) var history: [NFCScanResult] = AppPersistence.load([NFCScanResult].self, key: "nfc.history", fallback: [])
    @Published private(set) var status = "Ready"
    @Published private(set) var availabilityDetail = NFCService.currentAvailabilityDetail()

    #if canImport(CoreNFC)
    private var session: NFCNDEFReaderSession?
    private var pendingWriteMessage: NFCNDEFMessage?
    #endif

    @discardableResult
    func beginRead() -> Bool {
        #if canImport(CoreNFC)
        guard NFCNDEFReaderSession.readingAvailable else {
            availabilityDetail = Self.currentAvailabilityDetail()
            status = "NFC reader unavailable. Check signing capability."
            return false
        }
        pendingWriteMessage = nil
        availabilityDetail = Self.currentAvailabilityDetail()
        status = "Hold near an NFC tag."
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Scan an NDEF tag"
        session?.begin()
        return true
        #else
        status = "CoreNFC is unavailable in this build."
        availabilityDetail = Self.currentAvailabilityDetail()
        return false
        #endif
    }

    @discardableResult
    func beginWrite(text: String) -> Bool {
        #if canImport(CoreNFC)
        guard NFCNDEFReaderSession.readingAvailable else {
            availabilityDetail = Self.currentAvailabilityDetail()
            status = "NFC writer unavailable. Check signing capability."
            return false
        }
        let payload: NFCNDEFPayload
        if let url = URL(string: text), url.scheme != nil {
            payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) ?? NFCNDEFPayload(format: .nfcWellKnown, type: Data([0x55]), identifier: Data(), payload: Data(text.utf8))
        } else {
            payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: Locale.current) ?? NFCNDEFPayload(format: .nfcWellKnown, type: Data([0x54]), identifier: Data(), payload: Data(text.utf8))
        }
        pendingWriteMessage = NFCNDEFMessage(records: [payload])
        availabilityDetail = Self.currentAvailabilityDetail()
        status = "Hold near a writable NFC tag."
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold near a writable NDEF tag"
        session?.begin()
        return true
        #else
        status = "CoreNFC is unavailable in this build."
        availabilityDetail = Self.currentAvailabilityDetail()
        return false
        #endif
    }

    func refreshAvailability() {
        availabilityDetail = Self.currentAvailabilityDetail()
    }

    func clearHistory() {
        history = []
        lastResult = nil
        AppPersistence.save(history, key: "nfc.history")
    }

    func exportHistoryJSON() -> String {
        guard let data = try? JSONEncoder().encode(history),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    private func store(title: String, payload: String, detail: String) {
        let result = NFCScanResult(date: Date(), title: title, payload: payload, detail: detail)
        lastResult = result
        history.insert(result, at: 0)
        history = Array(history.prefix(100))
        AppPersistence.save(history, key: "nfc.history")
    }

    static func currentAvailabilityDetail() -> String {
        #if canImport(CoreNFC)
        if NFCNDEFReaderSession.readingAvailable {
            return "CoreNFC reports the NDEF reader is available on this signed build."
        }
        #if targetEnvironment(simulator)
        return "The iOS simulator cannot scan NFC tags. Test this module on a physical NFC-capable iPhone."
        #else
        return "CoreNFC reports NFC reading is unavailable. On a physical iPhone this usually means the app was signed without the NFC Tag Reading capability or without the NFC reader session formats entitlement in the provisioning profile."
        #endif
        #else
        return "CoreNFC was not linked into this build."
        #endif
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

    @discardableResult
    func add(title: String, trigger: String, action: String, symbol: String = "gearshape.2.fill", tintKey: String = "purple", isEnabled: Bool = true) -> AutomationRule {
        let rule = AutomationRule(
            title: title.isEmpty ? "Untitled Automation" : title,
            trigger: trigger.isEmpty ? "Manual trigger" : trigger,
            action: action.isEmpty ? "Log event" : action,
            symbol: symbol,
            tintKey: tintKey,
            isEnabled: isEnabled
        )
        rules.insert(rule, at: 0)
        persist()
        return rule
    }

    func setEnabled(_ rule: AutomationRule, enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index].isEnabled = enabled
        persist()
    }

    @discardableResult
    func run(_ rule: AutomationRule) -> String {
        let line = "\(Date().formatted(date: .abbreviated, time: .standard)): \(rule.title) -> \(rule.action)"
        executionLog.insert(line, at: 0)
        executionLog = Array(executionLog.prefix(80))
        return line
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
    @Published private(set) var currentDecibels: Float = -80
    @Published private(set) var isMonitoring = false
    @Published private(set) var permissionStatus = "Not requested"
    @Published private(set) var routeDescription = "Default"
    @Published private(set) var inputDescription = "Default"
    @Published private(set) var lastRecordingName = "No recording yet"

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var lastRecordingURL: URL?

    func refreshRoute() {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs.map(\.portName)
        let inputs = session.availableInputs?.map { "\($0.portName) (\($0.portType.rawValue))" } ?? []
        routeDescription = outputs.isEmpty ? "Default" : outputs.joined(separator: ", ")
        inputDescription = inputs.isEmpty ? "Default" : inputs.joined(separator: ", ")
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
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
            let directory = try Self.recordingsDirectory()
            let url = directory.appendingPathComponent("Toolkit-\(Int(Date().timeIntervalSince1970)).caf")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatAppleIMA4),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            lastRecordingURL = url
            lastRecordingName = url.lastPathComponent
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

    func playLastRecording() -> String {
        guard let lastRecordingURL else { return "No recording has been captured yet." }
        do {
            player = try AVAudioPlayer(contentsOf: lastRecordingURL)
            player?.prepareToPlay()
            player?.play()
            return "Playing \(lastRecordingURL.lastPathComponent)."
        } catch {
            return "Playback failed: \(error.localizedDescription)"
        }
    }

    private func updateMeter() {
        recorder?.updateMeters()
        let power = recorder?.averagePower(forChannel: 0) ?? -80
        currentDecibels = power
        let normalized = max(0, min(1, (Double(power) + 80) / 80))
        levels.append(normalized)
        levels = Array(levels.suffix(64))
    }

    private static func recordingsDirectory() throws -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Recordings", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

struct DeveloperUtilityService {
    func run(_ tool: DeveloperToolKind, input: String, pattern: String = "") -> String {
        do {
            switch tool {
            case .validateJSON:
                return try validateJSON(input)
            case .formatJSON:
                return try formatJSON(input)
            case .minifyJSON:
                return try minifyJSON(input)
            case .jsonKeys:
                return try jsonKeys(input)
            case .csvToJSON:
                return try csvToJSON(input)
            case .base64Encode:
                return Data(input.utf8).base64EncodedString()
            case .base64Decode:
                guard let data = Data(base64Encoded: input) else { return "Invalid Base64 input." }
                return String(decoding: data, as: UTF8.self)
            case .base64URLEncode:
                return Data(input.utf8).base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
            case .base64URLDecode:
                return decodeBase64URL(input)
            case .hexEncode:
                return Data(input.utf8).map { String(format: "%02x", $0) }.joined()
            case .hexDecode:
                return try hexDecode(input)
            case .sha256:
                return SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
            case .sha1:
                return Insecure.SHA1.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
            case .md5:
                return "Legacy MD5: " + Insecure.MD5.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
            case .hmacSHA256:
                let key = SymmetricKey(data: Data(pattern.utf8))
                return HMAC<SHA256>.authenticationCode(for: Data(input.utf8), using: key).map { String(format: "%02x", $0) }.joined()
            case .urlParse:
                return try parseURL(input)
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
            case .colorContrast:
                return try contrastRatio(input, pattern)
            case .textDiff:
                return textDiff(input, pattern)
            case .timestamp:
                return timestamp(input)
            }
        } catch {
            return error.localizedDescription
        }
    }

    func validateJSON(_ text: String) throws -> String {
        let data = Data(text.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        if let array = object as? [Any] {
            return "Valid JSON array with \(array.count) item(s)."
        }
        if let dictionary = object as? [String: Any] {
            return "Valid JSON object with \(dictionary.count) top-level key(s)."
        }
        return "Valid JSON \(type(of: object))."
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

    func jsonKeys(_ text: String) throws -> String {
        let data = Data(text.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            return "Top-level JSON value is not an object."
        }
        return dictionary.keys.sorted().joined(separator: "\n")
    }

    func csvToJSON(_ text: String) throws -> String {
        let rows = text.split(whereSeparator: \.isNewline).map { parseCSVLine(String($0)) }
        guard let headers = rows.first, !headers.isEmpty else { return "Enter CSV with a header row." }
        let objects = rows.dropFirst().map { row -> [String: String] in
            var object: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                object[header] = index < row.count ? row[index] : ""
            }
            return object
        }
        let data = try JSONSerialization.data(withJSONObject: objects, options: [.prettyPrinted, .sortedKeys])
        return String(decoding: data, as: UTF8.self)
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

    private func hexDecode(_ input: String) throws -> String {
        let hex = input.filter { $0.isHexDigit }
        guard hex.count.isMultiple(of: 2) else {
            throw NSError(domain: "DeveloperUtilityService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Hex input must contain an even number of digits."])
        }
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else {
                throw NSError(domain: "DeveloperUtilityService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid hex byte."])
            }
            data.append(byte)
            index = next
        }
        return String(data: data, encoding: .utf8) ?? data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    private func parseURL(_ input: String) throws -> String {
        guard let components = URLComponents(string: input), components.scheme != nil else {
            throw NSError(domain: "DeveloperUtilityService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Enter a valid URL with a scheme."])
        }
        var rows = [
            "Scheme: \(components.scheme ?? "")",
            "Host: \(components.host ?? "")",
            "Path: \(components.path.isEmpty ? "/" : components.path)"
        ]
        if let port = components.port {
            rows.append("Port: \(port)")
        }
        if let queryItems = components.queryItems, !queryItems.isEmpty {
            rows.append("Query:")
            rows.append(contentsOf: queryItems.map { "  \($0.name)=\($0.value ?? "")" })
        }
        return rows.joined(separator: "\n")
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

    private func contrastRatio(_ first: String, _ second: String) throws -> String {
        let left = try rgbComponents(first)
        let right = try rgbComponents(second)
        let firstLum = relativeLuminance(left)
        let secondLum = relativeLuminance(right)
        let ratio = (max(firstLum, secondLum) + 0.05) / (min(firstLum, secondLum) + 0.05)
        let aaNormal = ratio >= 4.5 ? "Pass" : "Fail"
        let aaLarge = ratio >= 3.0 ? "Pass" : "Fail"
        return String(format: "Contrast: %.2f:1\nWCAG AA normal text: %@\nWCAG AA large text: %@", ratio, aaNormal, aaLarge)
    }

    private func textDiff(_ left: String, _ right: String) -> String {
        let leftLines = left.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let rightLines = right.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let count = max(leftLines.count, rightLines.count)
        var rows: [String] = []
        for index in 0..<count {
            let old = index < leftLines.count ? leftLines[index] : ""
            let new = index < rightLines.count ? rightLines[index] : ""
            if old == new {
                rows.append("  \(old)")
            } else {
                if !old.isEmpty { rows.append("- \(old)") }
                if !new.isEmpty { rows.append("+ \(new)") }
            }
        }
        return rows.isEmpty ? "No text to compare." : rows.joined(separator: "\n")
    }

    private func timestamp(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let seconds = TimeInterval(trimmed) {
            return Date(timeIntervalSince1970: seconds).formatted(date: .complete, time: .complete)
        }
        return "\(Int(Date().timeIntervalSince1970))"
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var current = ""
        var isQuoted = false
        var iterator = line.makeIterator()
        while let character = iterator.next() {
            if character == "\"" {
                isQuoted.toggle()
            } else if character == ",", !isQuoted {
                values.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        values.append(current)
        return values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func rgbComponents(_ input: String) throws -> (red: Double, green: Double, blue: Double) {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
            throw NSError(domain: "DeveloperUtilityService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Enter 6-digit hex colors for contrast."])
        }
        return (
            Double((value >> 16) & 0xFF) / 255,
            Double((value >> 8) & 0xFF) / 255,
            Double(value & 0xFF) / 255
        )
    }

    private func relativeLuminance(_ color: (red: Double, green: Double, blue: Double)) -> Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(color.red) + 0.7152 * channel(color.green) + 0.0722 * channel(color.blue)
    }
}
