# NFC Module

## Purpose
Read supported NDEF tags and prepare safe write/history workflows.

## Public APIs / Frameworks
CoreNFC.

## Permissions and Entitlements
`NFCReaderUsageDescription` is included. The NFC Tag Reading capability may need to be enabled in Xcode when signing.

## Platform Limitations
iOS cannot emulate payment/access cards, cannot continuously scan in the background, and user action is required to start sessions.

## Testing Strategy
Requires a physical iPhone and supported NDEF tags.
