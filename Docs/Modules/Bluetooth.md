# Bluetooth Module

## Purpose
Scan and inspect BLE peripherals, display RSSI and advertisements, and provide a terminal-style foundation for UART-like devices.

## Public APIs / Frameworks
CoreBluetooth.

## Permissions and Entitlements
Bluetooth usage string is included. Background BLE modes are not enabled yet.

## Platform Limitations
iOS supports BLE, not classic Bluetooth discovery. Background scanning is constrained.

## Testing Strategy
Use preview devices on simulator and real BLE peripherals on device.
