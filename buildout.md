# Buildout Plan - Ultimate iPhone Developer Toolkit

## Agent Operating Instructions

This document is the live execution plan for building the platform described in `Plan.md` and visually directed by `UI UX.png`. Every AI coding agent working in this repository must keep this file current.

Required upkeep:

- Before starting a work session, read `Plan.md`, `UI UX.png`, and this `buildout.md`.
- Update **Current Execution State** before beginning meaningful implementation work.
- Mark checklist items as `[ ]`, `[~]`, or `[x]` as work moves from pending to active to complete.
- Add every material architecture decision to **Decision Log** with the date and reason.
- Add every scope change, new constraint, or discovered platform limitation to **Change Log**.
- Keep **Completed Work**, **In Progress**, **Next Up**, and **Blocked / Needs Input** accurate.
- When code changes alter the plan, update this document in the same commit or work session.
- Do not silently drop features from `Plan.md`; move them to **Deferred / Research Only** with a reason.
- Prefer public iOS APIs. Anything requiring special entitlements, sideload-only assumptions, or research-only access must be clearly labeled.
- Preserve the UI direction from `UI UX.png`: dark, compact, iOS-native, dashboard-oriented, blue-accented, card/list based, and power-user friendly.

## Current Execution State

- Current phase: Full prototype QA and macOS validation handoff
- Current step: Run GitHub Actions/Xcode build, then sign and test on iOS 26 hardware
- Overall status: Full local prototype implemented; Xcode/device validation pending
- Last updated: 2026-07-09
- Source plan: `Plan.md`
- UI reference: `UI UX.png`

## Completed Work

- [x] Read `Plan.md`
- [x] Inspected `UI UX.png`
- [x] Created initial `buildout.md`
- [x] Captured user decisions: unsigned build, GitHub Actions IPA compilation, personal iOS 26 target
- [x] Scaffolded `UltimateToolKit.xcodeproj` with app and unit-test targets
- [x] Implemented SwiftUI app shell with Home, Automation, Shortcuts, Widgets, and More tabs
- [x] Implemented dark compact design system matching the provided UI direction
- [x] Implemented primary module screens for Sensors, Bluetooth, NFC, Wi-Fi/Network, Developer Tools, Camera, Audio, Haptics, Widget Studio, Automation, Shortcuts, AI, and Settings
- [x] Added public-API service foundations for sensors, BLE scanning, NFC reading, network monitoring/HTTP, developer utilities, AppIntents, audio speech, and haptics
- [x] Added unsigned GitHub Actions IPA build workflow
- [x] Added README, module docs, `.gitignore`, privacy strings, and unit tests for utility functions
- [x] Ran static QA for project references, XML plist/scheme parsing, TODO/dead-code markers, and source/project consistency
- [x] Removed seeded sample/demo data from app source
- [x] Added persisted automation rules with create, toggle, run, delete, and execution log
- [x] Added BLE connect flow, GATT service/characteristic explorer, read/notify controls, and terminal write path
- [x] Added NFC write flow and persistent scan/write history
- [x] Added live camera preview and QR/barcode metadata detection
- [x] Added live audio meter and CoreHaptics pattern playback
- [x] Added Network.framework TCP port probe and local IP/interface detection
- [x] Added NFC entitlement file and wired it into the app target
- [x] Updated GitHub Actions to run simulator unit tests when an iPhone simulator is available
- [x] After first GitHub Actions exit-code-65 report, lowered minimum deployment target to iOS 17.0 for runner compatibility while preserving iOS 26 runtime support
- [x] After first GitHub Actions exit-code-65 report, switched project language mode to Swift 5 for CI compatibility
- [x] Removed incomplete AppIcon asset set that could fail asset catalog compilation
- [x] Reordered workflow to build/package IPA before optional simulator tests and upload build logs on failure

## In Progress

- [~] macOS/Xcode build validation and real-device hardware QA

## Next Up

- [x] Inspect repository structure after planning
- [x] Decide whether to scaffold a native Xcode project, Swift Package structure, or both
- [x] Create initial iOS app shell
- [x] Implement design system matching `UI UX.png`
- [ ] Run `xcodebuild` on macOS or GitHub Actions
- [ ] Resolve any Xcode/iOS 26 SDK compile issues found by CI
- [ ] Sign the unsigned IPA during sideloading
- [ ] Run real-device QA on iOS 26 for BLE, NFC, camera, microphone/audio, haptics, and permissions
- [ ] Confirm provisioning profile includes NFC reader session entitlement

## Blocked / Needs Input

- [x] Apple Developer Team ID, bundle identifier, and signing/provisioning choices are not yet known
- [x] Minimum iOS version should be confirmed before final project settings
- [~] Target device is described as iPhone 16e in `Plan.md`; simulator/device availability must be verified on macOS/Xcode
- [x] Sideload distribution path needs confirmation: Xcode install, TestFlight-like internal flow, AltStore, or exported IPA
- [~] Local Windows workspace cannot run `xcodebuild`, Swift compiler checks, iOS simulator, or real-device hardware tests

Resolved assumptions from user:

- Build unsigned artifacts. The user will sign while uploading/sideloading.
- Repository will be uploaded to GitHub.
- GitHub Actions should compile an unsigned IPA.
- Personal target phone runs iOS 26. The project uses an iOS 17.0 minimum deployment target so GitHub's available Xcode runners can compile it while still supporting iOS 26 devices.

## Product North Star

Build an all-in-one iPhone developer and power-user toolkit that exposes as many feasible device capabilities as iOS allows on a non-jailbroken sideloaded app. The app should feel like a compact native control room for developers: fast, dense, modular, searchable, local-first, privacy-conscious, and extensible.

The product combines ideas from developer utility apps, BLE/NFC scanners, network analyzers, sensor dashboards, Apple Shortcuts, Widgetsmith/Widgy, Scriptable/Pythonista, Home Assistant, and Node-RED, while remaining grounded in SwiftUI, Apple Human Interface Guidelines, public frameworks, and clear platform limitations.

## UI / UX Direction From `UI UX.png`

The app should visually match the provided mockup:

- Dark-first interface with near-black backgrounds and subtle translucent panels.
- iOS-native navigation with status bar, navigation title, back button, overflow menu, and bottom tab bar.
- Primary accent color: iOS system blue, with secondary semantic colors for modules.
- Compact rounded panels and rows, not marketing-style screens.
- Home screen named "Playground" with search, favorites grid, tool list, and bottom tabs.
- Favorites use colored module cards: Bluetooth, Wi-Fi, Sensors, NFC, Automation, Widget Studio.
- Module detail screens use grouped cards, section headers, toggles, lists, live values, and disclosure rows.
- Terminal screens use monospace text, black console surface, input bar, and mode segmented controls such as ASCII / HEX / BIN.
- Sensor screens use segmented filters and stacked live metric cards with tiny charts.
- Widget Studio uses a live preview canvas, component picker, theme controls, sliders, and compact editing rows.
- Automation has a tablet/wide layout option with automation list, rule builder, and settings panel.
- Navigation tabs: Home, Automation, Shortcuts, Widgets, More.
- Avoid oversized hero sections, decorative illustrations, or explanatory landing pages. The first screen is the usable toolkit.

## Technical Principles

- Use Swift 6 and SwiftUI for the main app.
- Use MVVM with dependency injection and protocol-backed services.
- Keep hardware APIs behind service abstractions so simulator mocks and tests are practical.
- Use Swift Concurrency and Combine where appropriate for streaming sensor, BLE, network, and automation events.
- Prefer SwiftData for app-owned persistence if the deployment target supports it; otherwise use Core Data or structured files.
- Keep all sensitive data local by default.
- Store secrets and API keys in Keychain.
- Request permissions only at point of use with clear descriptions.
- Provide graceful fallbacks for simulator, missing hardware, denied permissions, and unsupported entitlements.
- Separate research-only capabilities from shippable public-API features.
- Build vertical slices: each phase should leave the app runnable.

## Proposed Repository Structure

```text
UltimateToolKit/
  App/
    UltimateToolKitApp.swift
    AppState.swift
    AppRouter.swift
    DependencyContainer.swift
  DesignSystem/
    AppColors.swift
    AppTypography.swift
    AppSpacing.swift
    ModuleIcon.swift
    GlassPanel.swift
    MetricCard.swift
    ToolRow.swift
    TerminalView.swift
  Features/
    Home/
    Sensors/
    Bluetooth/
    NFC/
    Network/
    Camera/
    Audio/
    Haptics/
    Widgets/
    Shortcuts/
    Automation/
    DeveloperTools/
    AI/
    Settings/
  Services/
    Sensors/
    Bluetooth/
    NFC/
    Networking/
    Camera/
    Audio/
    Haptics/
    Automation/
    Persistence/
    Security/
    Logging/
  Models/
  Resources/
    Assets.xcassets/
    WidgetTemplates/
    AutomationTemplates/
  Extensions/
    ToolkitWidgets/
    ToolkitIntents/
  Tests/
    Unit/
    UITests/
  Docs/
    Modules/
  .github/
    workflows/
```

If the project is scaffolded differently by Xcode, preserve the same conceptual boundaries even if folder names differ.

## Architecture Blueprint

### App Shell

- [ ] Create SwiftUI app entry point.
- [ ] Add root navigation with bottom tabs for Home, Automation, Shortcuts, Widgets, More.
- [ ] Add adaptive navigation for iPad/wide screens using sidebar or split view.
- [ ] Add app-wide router for module deep links.
- [ ] Add dependency container for real services and mock services.
- [ ] Add logging service and in-app log model.
- [ ] Add permission state tracking.

### Design System

- [ ] Define dark-first color tokens matching the mockup.
- [ ] Define module colors and symbols.
- [ ] Build reusable card, row, section, toolbar, tab, metric, chart preview, and terminal components.
- [ ] Build compact segmented controls and icon buttons.
- [ ] Add dynamic type support without layout overlap.
- [ ] Add light mode after dark mode is stable.
- [ ] Add accessibility labels for icon-only controls.
- [ ] Verify major screens on compact iPhone and wide/iPad layouts.

### Data and Persistence

- [ ] Define common models: `LogEntry`, `Module`, `PermissionStatus`, `SensorSample`, `AutomationRule`, `ShortcutActionDefinition`, `ToolHistoryItem`.
- [ ] Add persistence for favorites, recent tools, logs, BLE devices, NFC history, network history, widgets, automations, and secrets references.
- [ ] Add import/export helpers for JSON/CSV where planned.
- [ ] Add data retention controls in Settings.

### Permissions and Entitlements

- [ ] Add privacy strings for Bluetooth, NFC, camera, photo library, location, microphone, speech recognition, motion/fitness if used, local network, and Face ID.
- [ ] Add required capabilities as implementation reaches each module.
- [ ] Document unsupported or special entitlements: Access WiFi Information, NFC, background modes, App Groups, Keychain Sharing, iCloud, HealthKit, HomeKit, Network Extension.
- [ ] Add a Settings permissions dashboard.

## Development Phases

### Phase 0 - Planning and Project Setup

Goal: turn the plan and UI reference into an executable roadmap, then scaffold the project.

- [x] Read `Plan.md`.
- [x] Inspect `UI UX.png`.
- [x] Create `buildout.md`.
- [x] Inspect the rest of the repository.
- [x] Decide native project format and minimum iOS version.
- [x] Scaffold iOS app project.
- [x] Add initial README with build/run instructions.
- [x] Add `.gitignore` suitable for Xcode/Swift.
- [~] Add SwiftLint or formatting guidance if the toolchain is available.
- [x] Create module documentation stubs under `Docs/Modules/`.

Exit criteria:

- App project exists and opens/builds.
- Root app shell is committed or ready.
- This buildout plan reflects actual scaffold choices.

### Phase 1 - Core Shell, Design System, and Home Dashboard

Goal: create the usable first screen and shared UI language.

- [x] Implement bottom tab shell.
- [x] Implement Home / Playground screen.
- [x] Add search field for modules.
- [x] Add favorites grid matching the mockup.
- [x] Add tools list with disclosure rows.
- [x] Add Settings / More placeholder.
- [x] Add mock module data.
- [x] Add reusable `MetricCard`, `ToolRow`, `ModuleCard`, `Panel`, and section header components.
- [x] Add basic app logging and recent event list.
- [~] Add snapshot or UI tests for root navigation if feasible.

Exit criteria:

- App launches into a polished Home screen resembling the provided UI.
- All primary tabs are reachable with placeholder content.
- The design system can support future modules without duplicating styling.

### Phase 2 - Developer Utilities Foundation

Goal: ship low-risk, offline developer tools first to prove architecture and create immediate value.

- [x] Developer Tools module landing screen.
- [~] JSON formatter, validator, minifier, and tree preview.
- [x] Base64 encode/decode.
- [x] URL encode/decode and parser.
- [x] UUID generator.
- [x] Hash generator using CryptoKit: SHA256, SHA1 if available/acceptable, MD5 only if clearly labeled legacy.
- [x] Regex playground.
- [x] JWT decoder.
- [ ] Color converter and contrast checker.
- [ ] Markdown preview/diff placeholder or first version.
- [ ] Tool history and copy/share actions.
- [x] Unit tests for pure utility functions.

Exit criteria:

- Developer utilities work offline.
- Tool history and copy flows are consistent.
- Utility functions have focused tests.

### Phase 3 - Sensor Dashboard

Goal: implement the live Sensors module with real values where public APIs allow and mocks where hardware is unavailable.

- [x] Sensor module screen with segmented filters: All, Motion, Environment, Device.
- [x] Battery level and charging state.
- [x] Thermal state.
- [x] Screen metrics: brightness, scale, max FPS.
- [x] Device info: model, OS, orientation.
- [x] Memory and storage stats.
- [x] Accelerometer stream.
- [x] Gyroscope stream.
- [ ] Magnetometer stream.
- [ ] Barometer / altimeter where available.
- [ ] Heading and compass with location permission handling.
- [ ] Location card with coordinates and accuracy.
- [ ] Microphone level card after Audio service exists.
- [x] Sensor sample charts using Swift Charts or lightweight custom sparklines.
- [x] Export sensor samples to CSV/JSON.
- [ ] AppIntent actions for basic sensor reads.
- [ ] Tests for sensor formatting and mock streams.

Exit criteria:

- Sensors screen resembles the mockup and updates live on device.
- Unsupported sensors display clear unavailable states.
- Simulator can use mock data.

### Phase 4 - Bluetooth Suite

Goal: implement BLE scanning, device detail, GATT exploration, and terminal foundations.

- [x] Bluetooth module screen matching the mockup.
- [x] Bluetooth state card with enabled/unavailable/powered-off states.
- [x] BLE scanning via `CBCentralManager`.
- [x] Device list with name, identifier, RSSI, and advertisement summary.
- [ ] Filters by name, UUID, RSSI, and favorites.
- [x] Connect/disconnect flow.
- [x] Service and characteristic explorer.
- [x] Read characteristic values.
- [x] Write characteristic values in ASCII/HEX/BIN modes.
- [x] Subscribe to notifications.
- [x] Terminal view for UART-like services.
- [~] RSSI chart and interaction logs.
- [ ] Save devices and custom labels.
- [ ] Export GATT logs.
- [ ] BLE automation events.
- [ ] BLE AppIntent actions.
- [x] Mock BLE service for simulator tests.

Exit criteria:

- Can scan, inspect, connect, read, write, and log BLE peripherals on device.
- Terminal UI matches the visual reference.
- BLE failures are logged and user-readable.

### Phase 5 - NFC Suite

Goal: add CoreNFC read/write flows with history and NDEF parsing.

- [x] NFC module landing screen.
- [x] Start NDEF read session from explicit user action.
- [~] Parse text, URI, contact, Wi-Fi, Bluetooth, and raw records where feasible.
- [~] Show tag type, payload size, writable status, and session result.
- [x] Write NDEF text and URL records.
- [x] Save tag scan history.
- [ ] Export/import custom tag dump JSON.
- [ ] Add known tag metadata placeholder database.
- [ ] Add NFC-triggered automation hooks where iOS allows.
- [ ] Add AppIntent actions where feasible.
- [ ] Document CoreNFC limitations in module UI and docs.

Exit criteria:

- NFC reads and writes supported tags on real device.
- Unsupported tag types fail gracefully.
- History is searchable and exportable.

### Phase 6 - Wi-Fi and Networking Suite

Goal: create network diagnostics, HTTP tooling, and local discovery.

- [x] Wi-Fi module screen matching the mockup.
- [x] Current network summary with entitlement-aware fallback.
- [x] IP address and interface display.
- [x] `NWPathMonitor` connectivity status.
- [ ] Ping tool.
- [ ] DNS lookup.
- [~] Port scanner with rate limits and warnings.
- [ ] Bonjour / mDNS browser.
- [ ] LAN scanner where feasible.
- [~] HTTP/REST client with headers, method, body, and response inspector.
- [ ] WebSocket console.
- [ ] MQTT explorer if dependency choice is approved.
- [ ] Wake-on-LAN packet sender.
- [ ] QR sharing for network/device info.
- [ ] Network history and export.
- [ ] AppIntent actions for common network tasks.

Exit criteria:

- Core diagnostics run on device.
- Networking tools use clear timeouts and cancellation.
- The UI communicates iOS network restrictions honestly.

### Phase 7 - Camera and Vision Suite

Goal: add live camera preview and high-value Vision tools.

- [x] Camera module screen.
- [x] Permission-gated live preview.
- [ ] Photo capture.
- [x] QR/barcode scanning.
- [ ] OCR using Vision.
- [ ] Face detection.
- [ ] Document scanner via VisionKit.
- [ ] Photo metadata / EXIF viewer.
- [ ] CoreImage filter pipeline starter.
- [ ] CoreML model runner placeholder or first classifier.
- [ ] AppIntent actions for scan/capture operations.
- [ ] Tests for parsing and view models with mocked camera outputs.

Exit criteria:

- Camera preview and scan flows work on device.
- Vision results are shown in compact, copyable result panels.
- Permission denial is handled gracefully.

### Phase 8 - Automation Engine and Shortcuts

Goal: connect modules through local rules and expose actions to Apple Shortcuts.

- [ ] Define automation models: trigger, condition, action, variable, execution log.
- [x] Build Automation tab list matching the mockup.
- [x] Build Create Automation screen with IF / THEN structure.
- [x] Add toggles for enabled, run immediately, notify when run.
- [x] Add manual trigger.
- [ ] Add time trigger.
- [ ] Add battery/sensor condition.
- [ ] Add BLE event trigger.
- [ ] Add NFC event trigger where feasible.
- [ ] Add network reachability trigger.
- [ ] Add actions: notification, HTTP request, haptic, log entry, open module.
- [ ] Add dry-run simulation mode.
- [x] Add execution logs and failure display.
- [ ] Define AppIntents foundation and first AppShortcuts.
- [ ] Add AppIntent categories for Developer Tools, Sensors, Bluetooth, NFC, Network, Camera, Audio, Haptics, Widgets, Automation, and AI as modules mature.

Exit criteria:

- Users can create and run simple automations locally.
- Shortcuts exposes initial useful actions.
- Automation execution is observable and debuggable.

### Phase 9 - Audio Suite

Goal: build audio diagnostics, recording, visualization, and speech utilities.

- [x] Audio module screen.
- [x] List current audio route and available inputs.
- [x] Microphone permission flow.
- [~] Live waveform.
- [ ] Spectrum analyzer using AVAudioEngine and FFT.
- [ ] Decibel meter.
- [~] Recording and playback.
- [ ] Speech-to-text.
- [x] Text-to-speech.
- [ ] Audio route controls where public APIs allow.
- [ ] Experimental data-over-sound research document.
- [ ] AppIntent actions for recording, transcribing, speaking, and level reads.

Exit criteria:

- Audio tools run in foreground with visible live feedback.
- Recording and speech flows are reliable.
- Experimental items are clearly separated from stable features.

### Phase 10 - Haptics Suite

Goal: provide a CoreHaptics editor and reusable pattern library.

- [x] Haptics module screen.
- [x] Detect haptic capabilities.
- [x] Preset pattern library.
- [x] Play/test haptic patterns.
- [~] Timeline editor for intensity and sharpness events.
- [x] Parameter sliders and playback controls.
- [ ] Import AHAP.
- [ ] Export AHAP JSON.
- [ ] Export Swift code snippet.
- [ ] Audio-to-haptics research/prototype.
- [ ] Automation and AppIntent hooks.

Exit criteria:

- Users can create, preview, save, and export haptic patterns.
- Unsupported devices show clear messaging.

### Phase 11 - Widget Studio and Live Activities

Goal: prototype widget builder with data binding and WidgetKit integration.

- [x] Widget Studio screen matching the mockup.
- [x] Live preview canvas.
- [x] Add component picker: Text, Gauge, Chart, Sensor, Image, Button.
- [ ] Component selection and inspector controls.
- [ ] Theme controls: system/custom, background, corner radius.
- [x] Data binding to battery, Wi-Fi, storage, uptime, sensor samples, and custom variables.
- [ ] Save widget definitions as JSON.
- [ ] Import/export widget templates.
- [ ] Widget extension target.
- [ ] Render saved widget definitions in WidgetKit where feasible.
- [ ] Add AppIntent-backed widget interactions.
- [ ] Live Activity prototype for one supported scenario.

Exit criteria:

- Users can design and save a widget-like layout in app.
- At least one actual WidgetKit widget displays app data.
- Builder UI stays compact and touch-friendly.

### Phase 12 - AI / ML Integration

Goal: add optional AI tools while keeping privacy explicit.

- [x] AI module screen.
- [ ] Secure API key storage.
- [ ] Prompt library.
- [ ] Cloud prompt request flow with user-provided API key.
- [ ] JSON transformation assistant.
- [ ] Natural language to automation draft generator.
- [ ] Natural language to widget draft generator.
- [ ] CoreML model runner.
- [ ] Vision + CoreML image classification flow.
- [ ] Clear local/cloud privacy labels.
- [ ] Tests for prompt templates and request builders.

Exit criteria:

- AI features are opt-in.
- Secrets are stored in Keychain.
- Generated automations/widgets require user review before activation.

### Phase 13 - Security, Privacy, and Settings

Goal: harden the app and make its power understandable and controllable.

- [ ] Settings module.
- [ ] Permissions dashboard.
- [ ] Data storage dashboard.
- [ ] Clear logs/history controls.
- [ ] Export all user data.
- [ ] Delete all user data.
- [ ] Face ID / Touch ID lock for sensitive sections.
- [ ] Keychain-backed secret management.
- [ ] Threat model document.
- [ ] Review every permission string.
- [ ] Review every network listener/client for validation and timeouts.
- [ ] Ensure no private APIs are used unless explicitly isolated as research-only.

Exit criteria:

- User can understand and control app permissions and stored data.
- Sensitive actions are gated and logged.
- Security review findings are documented.

### Phase 14 - Testing, CI, and IPA Build

Goal: create confidence and a repeatable build artifact.

- [x] Unit test target.
- [ ] UI test target.
- [ ] Mock hardware services for simulator.
- [x] Tests for developer utilities.
- [ ] Tests for automation engine.
- [ ] Tests for persistence migrations.
- [ ] Basic UI smoke tests for main tabs.
- [~] GitHub Actions workflow for build/test.
- [x] GitHub Actions workflow for archive/export IPA.
- [x] Document required secrets for signing.
- [ ] Add release checklist.

Exit criteria:

- CI builds the app.
- Tests run in CI where supported.
- Release IPA workflow is documented and ready for signing secrets.

### Phase 15 - Polish and Performance

Goal: make the platform feel coherent, fast, and reliable.

- [ ] Audit every screen against `UI UX.png`.
- [ ] Add loading, empty, error, permission-denied, and unsupported states.
- [ ] Add haptics for key interactions.
- [ ] Add command/search palette.
- [ ] Add favorites customization.
- [ ] Add module-specific onboarding only where necessary.
- [ ] Add performance throttling for sensors and scans.
- [ ] Add battery impact settings.
- [ ] Add accessibility pass: VoiceOver, Dynamic Type, contrast, hit targets.
- [ ] Add localization readiness.
- [ ] Final documentation pass.

Exit criteria:

- The app feels like a single polished platform rather than separate demos.
- Performance remains stable under long-running sensor, BLE, and network sessions.

## Module Documentation Template

Each module under `Docs/Modules/` should include:

```markdown
# Module Name

## Purpose
## User Stories
## UI Reference
## Public APIs / Frameworks
## Permissions and Entitlements
## Platform Limitations
## Architecture
## Data Models
## Services
## AppIntents / Shortcuts
## Widget Hooks
## Automation Hooks
## Error States
## Testing Strategy
## Security and Privacy Notes
## Deferred / Research-Only Ideas
```

## Feature Priority Matrix

| Priority | Feature Area | Reason |
| --- | --- | --- |
| P0 | App shell and design system | Required for all modules and visual consistency |
| P0 | Home / Playground | First screen and navigation hub |
| P0 | Developer utilities | Low-risk, immediately useful, testable |
| P0 | Sensor dashboard basics | Core promise of device capability visibility |
| P1 | Bluetooth suite | Major differentiator and visible in mockup |
| P1 | NFC suite | Major differentiator and shortcut/automation source |
| P1 | Network suite | Developer utility and diagnostics pillar |
| P1 | Automation basics | Connective tissue across modules |
| P1 | AppIntents foundation | Enables Shortcuts platform value |
| P2 | Camera / Vision | High-value but permission-heavy |
| P2 | Audio | High-value but needs careful performance handling |
| P2 | Haptics | Differentiated creative tool |
| P2 | Widget Studio | Large UI surface; should come after data sources exist |
| P3 | AI / ML | Optional and privacy-sensitive |
| P3 | Advanced scripting/plugin support | Powerful but high complexity |
| Research | NetworkExtension, packet capture, private APIs | Requires special entitlements or is unsuitable for public API build |

## Platform Limitation Register

- NFC cannot emulate payment/access cards on non-jailbroken iOS.
- NFC scanning must be user initiated and cannot continuously run in the background.
- BLE supports BLE, not classic Bluetooth discovery.
- BLE background behavior is limited and must use appropriate background modes.
- Wi-Fi SSID/BSSID access requires entitlement and location-related constraints.
- iOS apps cannot sniff arbitrary Wi-Fi packets with public APIs.
- Device-wide network usage is not generally available; track app-owned traffic instead.
- Ambient light has no direct public API; camera/ARKit estimates are approximate.
- CPU usage requires careful Mach API use and may be limited or considered sensitive.
- Background automation is constrained by iOS scheduling and AppIntents behavior.
- Widgets have refresh and interaction limits.
- HealthKit/HomeKit/iCloud capabilities require explicit entitlement setup.
- NetworkExtension and VPN-style capabilities are research-only unless entitlements are available.

## Testing Strategy

- Unit test pure functions first: JSON formatting, encoders, hashers, regex helpers, parser utilities, automation condition evaluation, BLE/NFC data parsers.
- Use protocol-backed service mocks for hardware modules.
- Use simulator mock streams for sensors, BLE devices, NFC tags, network responses, camera frames, and audio samples.
- Run manual device tests for Bluetooth, NFC, camera, microphone, haptics, location, and widgets.
- Add UI smoke tests for tab navigation and key module entry points.
- Add performance tests for long-running sensor streams, BLE scans, and audio visualization.
- Maintain a manual hardware test matrix for device model, iOS version, permission state, and expected result.

## CI / Release Plan

- Use GitHub Actions on macOS for build and tests.
- Add an unsigned simulator build workflow first.
- Add signed archive/export workflow after signing secrets are known.
- Required release secrets likely include certificate, certificate password, provisioning profile, keychain password, export options plist, team ID, and bundle ID.
- Archive IPA artifacts on tagged releases and manual dispatch.
- Keep a release checklist covering version bump, changelog, permission review, test pass, signing verification, and install test.

## Security and Privacy Plan

- Local-first by default.
- No analytics unless explicitly added and documented.
- Store secrets only in Keychain.
- Use Face ID / Touch ID for sensitive tools and secret access.
- Make cloud AI opt-in and API-key based.
- Log powerful actions locally with user-visible history.
- Do not execute imported scripts, automations, or templates without user review.
- Validate URLs, ports, payload sizes, and file imports.
- Add rate limits for scanners and network tools.
- Provide full data export and delete controls.

## Decision Log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-07-09 | Use `buildout.md` as the live implementation ledger | User explicitly requested a complete development plan that future AI agents keep updated |
| 2026-07-09 | Preserve `UI UX.png` as the primary visual target | The mockup defines the product feel more concretely than text alone |
| 2026-07-09 | Prioritize app shell, design system, developer utilities, and sensor basics before hardware-heavy modules | This creates a runnable foundation and reduces risk before entitlements and real-device testing |
| 2026-07-09 | Support iOS 26 while using an iOS 17.0 minimum deployment target | Newer iOS versions run apps with lower deployment targets, and GitHub runners may not support an iOS 26 minimum SDK yet |
| 2026-07-09 | Build unsigned app artifacts in CI | User will sign during sideload/upload, so GitHub Actions packages an unsigned IPA |
| 2026-07-09 | Use a manually committed `.xcodeproj` instead of a generator | Avoids adding network-installed tooling to GitHub Actions and keeps the repo self-contained |
| 2026-07-09 | Use public APIs and simulator-safe mocks for hardware-heavy modules | Current workspace cannot run iOS hardware tests, and the app must stay non-jailbroken |
| 2026-07-09 | Remove seeded demo data from runtime source | User requested a prototype ready for real testing with no sample data |
| 2026-07-09 | Add minimal NFC reader-session entitlement file | NFC read/write tests require the entitlement when the user signs the app |
| 2026-07-09 | Set Swift strict concurrency checking to minimal | Delegate-heavy CoreBluetooth/CoreNFC/AVFoundation prototypes use callback bridges that should be hardened after CI confirms compile behavior |
| 2026-07-10 | Use Swift 5 language mode for the GitHub Actions prototype build | This is more compatible across GitHub-hosted Xcode runners while retaining modern Swift syntax supported by current compilers |

## Change Log

| Date | Change | Impact |
| --- | --- | --- |
| 2026-07-09 | Initial buildout plan created from `Plan.md` and `UI UX.png` | Establishes phased implementation roadmap and live status tracking |
| 2026-07-09 | Added native SwiftUI iOS project, app target, unit-test target, shared scheme, unsigned IPA workflow, README, docs, and `.gitignore` | Repository can be pushed to GitHub and built by Actions on macOS |
| 2026-07-09 | Added first implementation slice across all major modules | App has navigable UI and functional foundations for developer tools, sensors, BLE, NFC, network, automation, widgets, camera, audio, haptics, AI, shortcuts, and settings |
| 2026-07-09 | Local QA limited to static checks because this workspace has no `xcodebuild` or Swift compiler | Full compile, simulator, and real-device QA must run on macOS/GitHub Actions and iOS 26 hardware |
| 2026-07-09 | Promoted implementation to full testable prototype | Added persisted automations, BLE GATT flows, NFC write/history, camera preview/code detection, audio meter, CoreHaptics playback, TCP probe, entitlements, and simulator-test CI step |
| 2026-07-09 | Removed runtime-seeded sample/demo data | App now starts with empty user-owned state or live device readings |
| 2026-07-10 | Hardened CI after first exit-code-65 report | Lowered minimum deployment target, switched to Swift 5 language mode, removed incomplete app icon asset, moved optional tests after IPA packaging, and added uploaded build logs |

## Deferred / Research Only

- Packet capture or VPN-level inspection through NetworkExtension unless proper entitlements are available.
- Private APIs for cellular signal, audio codecs, system-wide network usage, or other restricted device data.
- Full Python/Lua embedded runtimes until the native app foundation is stable.
- Third-party plugin loading until module boundaries and security model are proven.
- Audio-over-ultrasound modem as experimental after core Audio module exists.
- HealthKit/HomeKit/Matter integration until the core automation and permissions architecture is stable.

## Definition of Done

A feature is complete only when:

- It is implemented through the established architecture.
- It matches the visual language of `UI UX.png`.
- It has loading, empty, error, permission-denied, and unsupported states where applicable.
- It works with mock data on simulator where hardware is unavailable.
- It has real-device testing notes if hardware APIs are involved.
- It has appropriate unit/UI tests or a documented reason tests are not practical.
- It has module documentation updated.
- `buildout.md` status, completed work, and next steps are updated.
