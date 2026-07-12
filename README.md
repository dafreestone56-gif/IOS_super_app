# Ultimate iPhone Developer Toolkit

Personal SwiftUI iOS toolkit inspired by `Plan.md` and the `UI UX.png` reference. The app supports your iOS 26 phone while using an iOS 17.0 minimum deployment target for GitHub runner compatibility. It builds unsigned and is intended to be signed by the user during sideloading.

## Build

Open `UltimateToolKit.xcodeproj` on macOS with an Xcode version that supports iOS 26, then build the `UltimateToolKit` scheme.

GitHub Actions also builds an unsigned device IPA:

```sh
xcodebuild -project UltimateToolKit.xcodeproj -scheme UltimateToolKit -configuration Release -destination "generic/platform=iOS" CODE_SIGNING_ALLOWED=NO build
```

The workflow packages the resulting `.app` into `UltimateToolKit-unsigned.ipa` for user-side signing.
It also attempts unit tests on the first available iPhone simulator in the macOS runner.

## Sideload Signing Requirements

The unsigned IPA contains an app target and a WidgetKit extension target. When signing for device install, sign both:

- `com.personal.playgroundtoolkit`
- `com.personal.playgroundtoolkit.widgets`

The host app provisioning profile needs NFC Tag Reading with `NDEF` and `TAG` reader session formats. The host app and widget extension profiles both need the App Group `group.com.personal.playgroundtoolkit`; otherwise NFC will report unavailable and the widget may not appear or receive Widget Studio drafts.

## Current Scope

- SwiftUI app shell with Home, Automation, Shortcuts, Widgets, and More tabs.
- Dark compact UI matching the provided mockup direction.
- Developer tools: JSON formatting/minifying, Base64, SHA-256, URL tools, UUID, JWT decode, regex.
- Sensor dashboard with live battery/display/device values, motion data where available, and CSV snapshot logging.
- BLE scanner, connect flow, GATT service/characteristic explorer, read/notify controls, and terminal write path using CoreBluetooth.
- NFC read/write sessions with persistent local history using CoreNFC.
- Network monitor, local interface/IP detection, HTTP GET client, and TCP port probe.
- Widget Studio in-app builder prototype bound to live sensor/network values.
- Camera permission flow, live AVCapture preview, and QR/barcode metadata detection.
- Audio microphone meter and text-to-speech tools.
- CoreHaptics pattern playback with intensity/sharpness controls.
- Local persisted automation rules with create, toggle, run, delete, and execution log.
- Initial AppIntents for battery level and JSON formatting.

Keep `buildout.md` updated during every implementation session.

## GitHub Actions Visibility

The real workflow lives at `.github/workflows/ios-unsigned-ipa.yml`. If your upload tool hides or skips `.github`, use `GITHUB_ACTIONS_SETUP.md` and the visible backup at `GITHUB_ACTIONS_VISIBLE/ios-unsigned-ipa.yml` to recreate the workflow from GitHub's web editor.
