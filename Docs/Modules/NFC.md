# NFC Module

## Purpose
Read supported NDEF tags and prepare safe write/history workflows.

## Public APIs / Frameworks
CoreNFC.

## Permissions and Entitlements
`NFCReaderUsageDescription` is included. The app target also includes `com.apple.developer.nfc.readersession.formats` with `NDEF` and `TAG`.

When this repository builds an unsigned IPA, the final sideload/signing step still has to use a provisioning profile with the NFC Tag Reading capability enabled. If the signed build reports `NFCNDEFReaderSession.readingAvailable == false` on a physical NFC-capable iPhone, treat that as a signing/capability mismatch first.

## Platform Limitations
iOS cannot emulate payment/access cards, cannot continuously scan in the background, and user action is required to start sessions. CoreNFC support is limited to Apple-supported tag families and NDEF-style workflows.

## Testing Strategy
Requires a physical iPhone and supported NDEF tags.
