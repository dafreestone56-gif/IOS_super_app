# Ultimate iPhone Developer Toolkit – Plan

## Executive Summary  
Design an all-in-one “Swiss Army Knife” app for iPhone that empowers developers and power users by exposing every feasible device capability. The toolkit (targeted at the iPhone 16e) will combine features of Flipper Zero, Apple Shortcuts, Pythonista, Scriptable, NFC/BLE/network scanners, Home Assistant companion, and more, while conforming to Apple’s Human Interface Guidelines.  Being a *sideloaded* app (non-App Store distribution but **non-jailbroken**), it can push the limits of iOS frameworks and entitlements (for example, using advanced networking or NFC write features not normally App Store–approved). Our research has identified numerous existing utilities and libraries that inspire this design, from general developer tools to specialized sensor explorers. We will architect the app in modular Swift (SwiftUI, MVVM, DI, feature modules) with a plugin-style extensible core. Every feature will document required frameworks, entitlements, and data flows so that an AI coding agent can implement it directly.

## Feature List  
The toolkit will provide the following core feature categories:

- **Developer Utilities**: JSON/YAML/CSV viewers, formatters and converters, cryptographic hashers, color pickers, regex testers, UUID/JWT/Base64 encoders, HTTP/REST/GraphQL clients, Markdown diff/preview, file explorers, SQLite browser, console/log viewer, etc.  Existing examples like *DevKit* showcase 30+ offline tools. We will far exceed this by integrating system info (UIDevice data) and dynamic debugging tools.

- **Automation Engine**: A built-in rule engine with triggers, conditions, and actions. Support event triggers (Bluetooth/NFC events, location change, time schedules, sensor thresholds), REST/Webhook triggers, and JavaScript expressions. Variables and templates will allow complex logic and responses (e.g. “When my BLE sensor reports low battery, send HTTP request”). See how IFTTT uses simple “if this then that” logic for inspiration, but embed it *locally on device* and vastly more extensible.

- **Shortcuts Integration (AppIntents)**: Expose hundreds of Shortcut actions covering all modules. Categories include: Bluetooth, NFC, Camera, Motion, Audio, Network, Widgets, Variables, Files, Sensors, REST/JSON, Clipboard, Text/Regex, Images/ML, Device Info, Diagnostics, etc. For example, Pythonista allows invoking scripts from Shortcuts; Scriptable can present outputs to Siri and the Home Screen. We will implement AppIntents to enable background tasks and shortcuts (e.g. “Scan for BLE devices”, “Read NFC tag”, “Analyze camera frame”, “Show battery stats”).

- **Sensor Dashboard**: Real-time display of every available sensor and system statistic. This includes motion sensors (accelerometer, gyroscope, magnetometer, compass), location & heading (CoreLocation), altitude/barometer (CMAltimeter), GPS coordinates, battery level/charging state (UIDevice), thermal state (ProcessInfo.thermalState), orientation (UIDevice.orientation), ambient light *(if accessible via ARKit or screen sensors)*, camera (exposure, ISO, frame rate, depth data on LiDAR devices), microphone levels, face detection, proximity sensor, screen metrics (resolution, brightness, refresh rate), audio routing, memory/CPU usage (via mach APIs or ProcessInfo), network traffic (bytes sent/recv per interface), and even Motion or HealthKit data (HealthKit access could be research-only).  Apps like **EXA Sensor** already display many of these in a unified view, and **Device Monitor Z** (a “iDevice Monitor”) shows CPU/RAM/storage, network tests, WiFi scan, sensors, and widgets. We will include all these and more, with graphs and logs, and allow exporting data.

- **Bluetooth Suite**: Advanced BLE toolkit using CoreBluetooth. Features include: continuous BLE scanning with RSSI charts, filters by name/UUID, beacon and advertisement decoding; service/characteristic explorer when connected; live notifications display; read/write values in ASCII/HEX/byte modes; subscribe and log history of changes; save/favorite devices and custom profiles (preset reads/writes); export GATT logs (CSV, JSON); simple terminal-like UI for sending raw data; and automation triggers on BLE events.  We draw from apps like LightBlue, nRF Connect, and BLE Scanner. Notably, iOS can act as both BLE Central and Peripheral (iOS 6+), enabling two-iPhone BLE “chat” if one advertises and one connects. We will document this limitation and implement chat if possible, plus unique ideas like scripting BLE sequences or exporting custom BLE packets.  

- **NFC Suite**: Full CoreNFC integration. Capabilities: read NFC tag UID, type, memory dump; parse NDEF records (URI, text, contact, Wi-Fi, Bluetooth, etc); write NDEF records to writable tags; clone and duplicate NFC data; secure message exchange (NFC NDEF push if applicable); history of tag scans; search a known tag DB by UID; and tag-based automation triggers. For inspiration, *NFC Tools* supports reading/writing all NDEF tags and many operations. iOS limitations include: only NFC Type 1–5 tags, NDEF format only; writing started in iOS13 (our reference to NXP TagWriter notes native iOS NDEF support as of iOS 26.2). We will highlight that limitation (no EMV card emulation, for example), and provide best effort within iOS’s CoreNFC. Automation hooks: e.g. “trigger shortcut when this specific tag scanned.”

- **Wi-Fi & Networking Suite**: Use Network.framework, CFNetwork, and BSD sockets to implement: current Wi-Fi info (SSID, BSSID, IP, DNS, gateway if allowed); LAN scanning (ping sweep, mDNS browse); Internet utilities (ping, traceroute, port scan, DNS lookup, whois) as seen in Network Analyzer apps; speed test (download/upload via HTTP or speedtest.net APIs); HTTP/REST client with custom requests; WebSocket console; raw TCP/UDP client/servers; MQTT client; multicast discovery; Wake-on-LAN (magic packet); local network chat; and sharing info via QR codes. We will note iOS restrictions: since iOS 13, accessing SSID requires “Access WiFi Information” entitlement; active network scanning on iOS is limited compared to macOS (Apple still allows ping/traceroute with standard sockets). We will include a Bonjour browser (using `NetServiceBrowser`) and maybe an mDNS discovery feature.  Device Monitor Z already includes speed test, LAN scan, ping, traceroute, port/DNS tests, which we will emulate and improve with a better UI.

- **Camera Suite**: Advanced camera and image processing features via AVFoundation, Vision, and ARKit. Include live camera preview, capturing images/video, and frame analysis: OCR (Vision text recognition), barcode/QR scanning (Vision), object detection (Vision/CoreML), document scanning (VisionKit), face and landmark detection (Vision), depth analysis (LiDAR-enabled phones via ARKit). Support capturing RAW images (AVCapturePhotoOutput), reading image metadata (Exif). Offer an image editing/processing pipeline: filters (CoreImage), Metal shader examples, CoreML models. Build-in automation: e.g. on event, auto-scan for QR; Shortcut actions: “Capture photo of object and identify it.” For UI, we can emulate functionality of dedicated scanning apps but integrated into toolkit.

- **Audio Suite**: Full control of audio IO. List available input/output devices (built-in mic, connected headsets, AirPods, Bluetooth audio). Route audio (AVAudioSession). Visualizers: live waveform, spectral analyzer (e.g. via AVAudioEngine FFT). Record audio or stream via sockets. Speech-to-text (iOS Speech framework) and text-to-speech (AVSpeechSynthesizer). Experimental: data-over-sound (modem via audio). For inspiration, the app *Waver* sends text via ultrasonic sound; we could include a similar mode for near-field data exchange (microphone permission needed). Also include basic beat detection or sound-triggered automation.  

- **Vibration & Haptics**: Use CoreHaptics for custom tactile feedback. Provide a Haptic Editor: timeline-based pattern designer, similar to *Haptic Pro*. Allow drawing intensity/sharpness curves, combining with audio, or import from audio/video (Haptic Pro supports audio-to-haptics). Offer presets (e.g. standard notifications). Enable exporting and sharing AHAP patterns, and triggering these patterns via Shortcuts. Build a library of common patterns. Document CoreHaptics caps and the differences between standard UIFeedbackGenerator and custom haptics (e.g. only certain devices support advanced haptics).  

- **Widget Studio**: A drag-and-drop visual builder for iOS Home Screen and Lock Screen widgets (iOS 14+). Support *Custom Layouts* and interactive elements. Users can drag UI components (text, images, charts, buttons, toggles) and bind them to data sources (sensors, API results, user variables). Provide templates (e.g. weather chart, system monitor, home automation control). Real-time preview of widgets. Allow scripting or formula fields for dynamic content. Support Lock Screen Live Activities integration. Include theme engine and allow import/export of widget definitions (JSON or a URL scheme). For inspiration, *Widgy* lets users fully customize widgets with layers; *Widgetsmith* offers many pre-built widget types with actions. We will merge these ideas: allow both visual building and code, plus community templates. Key is easy reuse of components.

- **Developer Dashboard**: A home screen/dashboard inside the app to monitor logs, recent events, device metrics, and shortcuts. Think of a VS Code or Grafana-like console for iOS system data. Could include a console log viewer (see Crash reports or NSLog output via a File Provider extension?), a JSON & API playground, network request inspector, and environment variables. Examples: DevKit has a smart history; we will allow multi-panel views (like split screen with sensor graphs and log). Provide theming (dark mode), search, and onboarding tips.

- **AI/ML Integration**: Integrate on-device or cloud AI. Allow calling cloud APIs (OpenAI GPT, image recognition APIs) and local CoreML models. Features: “ChatGPT” style prompt library, automated shortcut/widget generation from natural language (e.g. “Create a shortcut that turns on Wi-Fi at 9pm”). Possibly include Apple’s MLKit or stable diffusion-like image generation (if computationally feasible). Also use ML for image recognition (CoreML). Provide voice assistant hooks (via SiriKit/Intents or speech commands). We note IFTTT already offers AI “Prompt” actions; we aim to build similar smart automations locally.

- **Security & Privacy**: Document necessary permissions and entitlements for each feature (e.g. `NFCReader`, `BluetoothAlways`, `LocationWhenInUse`, `Microphone`, `Camera`, `HealthKit`, etc). Use Apple’s best practices: request only needed permissions, explain usage, handle denial gracefully. Use Keychain/Encrypted storage for sensitive data. Outline Threat Model: as a developer tool, it has to be security-savvy (avoid executing untrusted code, sandbox boundaries). Face ID/Touch ID can be used to lock critical sections. Discuss App Sandbox limits: we cannot access other apps’ data, and background tasks are limited by OS.

- **GitHub Repository & CI**: Structure the repo as modular Swift packages or Xcode frameworks. Folder layout: `Sources/Features/XYZ`, `Services/Networking`, `UI/Modules`, `Models`, `Resources`, `Tests`. Include documentation (docc, README, changelog), code style/lint scripts (SwiftLint), and unit/UI tests placeholders. For CI, use GitHub Actions: a macOS runner with Xcode to build & archive the app. For example, define a workflow with `runs-on: macos-latest`, use `actions/checkout@v3`, `actions/setup-xcode@v3`, then `xcodebuild` to archive and export an IPA. The final IPA is uploaded as an artifact for installation. We will write the exact YAML specifying automatic builds on push, tag, or manual dispatch, caching Swift Package Manager or CocoaPods dependencies, and including codesigning steps (import .p12 certificate and provisioning profile via secrets as shown in examples).

- **UI/UX Design**: Follow Apple’s Human Interface Guidelines for clarity and performance, but favor power-user features. Use a clean, modular SwiftUI interface. Key ideas: a collapsible sidebar (like Xcode or VS Code) to switch between tools; card/grid views for sensor dashboards (inspired by Home Assistant lovelace cards); command/search palettes (inspired by Raycast) for quick action; dark/light theming. Dashboard screens (a la Grafana or Node-RED) can show graphs. Use gestures: e.g. drag a service into a flow. Investigate widgets collection view (like Widgetsmith’s theme screens). Provide an “Inspector” style overlay for detailed views.

Each feature module will be documented with: Purpose, User Story, Architecture (MVVM + specific frameworks), Required Apple frameworks (e.g. CoreBluetooth, CoreNFC), Permissions (Privacy keys, entitlements), Platform limitations (e.g. iOS NFC constraints, background mode restrictions), Implementation notes, Shortcut/Widget hooks, UI mockups, Testing strategy, and Risk (e.g. unstable private APIs avoid, performance issues).

## Competitive Analysis  
We surveyed many existing tools for inspiration:

- **DevKit – Developer Utilities** (Apple App Store): *DevKit* provides 30+ offline dev tools (JSON/YAML formatters, Base64, JWT, hash calc, etc.) with a privacy-first design. *Strengths:* All tools offline, fast, clean UI. *Weaknesses:* Limited to data-formatting; lacks hardware/sensor integration. *Ideas:* “Smart history” and instant copy-paste actions are useful. *To Copy:* Building multiple small tools into one app, offline-first approach. *To Improve:* Expand to network/API tools, link sensor data into tools. UI is simple list+detail.

- **Pythonista 3 (omz:software)**: A full Python IDE on iOS. *Strengths:* Rich language support (requests, numpy, UI, sensors via `pythonista` modules). Integrates with Shortcuts/Siri, offline docs. *Weaknesses:* UI is dated, paid app with no updates recently (may be stuck on Python3.8?), no package manager for C libs. *Ideas:* In-app code execution, custom keyboard. *Unique:* Run Python scripts with full stdlib + some scientific libs. *Missed:* Cannot pip-install large libraries. *UX:* Familiar editor for coders, breakpoints. *Architecture:* Embeds CPython; heavy use of `objc_util`. 
  - *Opportunity:* Provide multiple script engines (Python, Lua, JS). Pythonista’s seamless script invocation via share/keyboard should inspire built-in scripting support.

- **Scriptable (Simon Støvring)**: JavaScript automation on iOS. *Strengths:* Deep OS integration (widgets, Siri Shortcuts support, share extension, iCloud sync). *Weaknesses:* JavaScript-specific, no visual debugging. *Unique:* Lock Screen widgets running scripts; automatic Siri parameter support. *Copy:* Using AppIntents (the modern replacement) for shortcuts, and enabling widget scripts. *Improve:* Add environment variables, better debugging. 

- **iSH (Theodore Dubois)**: Alpine Linux emulation on iOS. *Strengths:* Provides a full shell, apt package manager, SSH, compiler; open source. *Weaknesses:* CPU-heavy, some system calls missing. *Unique:* Native-ish Linux on non-jailbroken iOS. *Missed:* Limited networking (no tun, some X86 syscalls missing). *Idea:* We won’t embed iSH, but could call out to a “Terminal” module for simple shell utilities or use iSH as a coding example of filesystem and concurrency work.

- **Device Monitor Z (iDevice Monitor)**: Diagnostic tool with CPU/GPU info, memory/storage, battery, sensors, network tools. *Strengths:* Very comprehensive (shows almost everything via tabs). *Weaknesses:* Overwhelming UI, ad-supported. *Unique:* Includes “Anti-Mosquito” (ultrasonic device), decibel meter, LAN scanner, Bonjour browser. *Copy:* Aggregate sensors (gyro, barometer, location) and system info. *Improve:* Better UI layout, integrate user flow. *Note:* If we include every sensor and network test, this app is a direct competitor.

- **Network Analyzer (Techet)**: Wi-Fi diagnostics with ping, traceroute, port scan, Wi-Fi LAN scan. *Strengths:* All-in-one. *Weaknesses:* iOS scanning is limited (it uses local subnet scan only). *Unique:* Fixed suite of networking tools. *Copy:* Standard tools like ping/traceroute easily accessible. *Improve:* Better integration (e.g. store scan results as automation triggers).

- **Fing – Network Scanner**: Network discovery and security tool. *Strengths:* Recognizes devices by name/vendor, speed tests, router security info. *Weaknesses:* Requires Internet server for some features, privacy concerns. *Unique:* Popular and easy UI for non-tech users. *Copy:* Device recognition hints, phone alerts. But we focus on developer use, so skip non-local.

- **BLE Scanner 4.0 (Bluepixel)** & **LightBlue** & **nRF Connect**: All provide BLE scanning/connectivity. *Strengths:* Live RSSI, GATT exploration, logs. *Weaknesses:* UI not tailored for novices. *Unique:* LightBlue can advertise custom peripheral; nRF Connect supports DFU and peripheral mode. *Missed:* They lack higher-level scripting. *Copy:* Terminal mode (ASCII/HEX editor), advertising as peripheral, RSSI graph. *Improve:* Combine them with automation (e.g. “notify me when device detected with RSSI > threshold”).

- **NFC Tools (Wakdev)** & **NXP TagWriter**: Tag read/write apps. *Strengths:* NDEF records handling, format/clone tags. *Weaknesses:* On iOS, limited by CoreNFC (no proprietary cards). *Unique:* Tag cloning, advanced commands. *Missed:* Developer-oriented views. *Copy:* Tag info screens, history of reads. *iOS Limit:* Only NDEF (types 1–5) per Apple’s Core NFC.

- **Home Assistant Companion (Nabu Casa)**: Smartphone app for home automation. *Strengths:* Integration with thousands of devices/services, mobile sensors for HA, custom widgets. *Weaknesses:* Requires HA server, complex setup. *Ideas:* It shows how to integrate with smart home triggers and display live device data; we can borrow the idea of a dashboard and Shortcuts automation of smart devices (but in our case, “smartphone as a hub”). *Unique:* Voice assistant, HomeKit/Matter support in app. We will implement a subset: the idea of controlling IoT devices via the phone (e.g. BLE, network, and Shortcuts triggers).

- **Node-RED (with mobile client)**: Flow-based automation. No official iOS version, but *Remote-RED* app provides access. *Idea:* The notion of flow diagrams for automation inspires our Automation Engine UI. We will offer a visual editor for conditions/actions. Also mention Node-RED’s use of MQTT/REST which we will support in our network suite.

- **Widgetsmith** and **Widgy**: Popular widget creator apps. Widgetsmith provides ready widget templates and scheduling. Widgy offers fully custom layer-based design. We will combine both paradigms: drag-and-drop plus a rich library of building blocks, with customization that Widgetsmith lacks (free-form shape). *Missed:* Widgetsmith users ask for shape editing; we will allow arbitrary layout within widget bounds.

- **IFTTT**: Automation platform. Provides “if-this-then-that” between 1000+ services. *Strengths:* Very broad integrations, no coding. *Weaknesses:* Cloud-based, no local device triggers (except via app). We take inspiration from the simple UI (creating “recipes”) and expansive integrations. In our local context, we would implement similar conditional logic but triggered by local sensors/network, and allow calling REST/Webhook actions. IFTTT’s mention of location-based features and voice integration suggests we should use CoreLocation and integrate voice (via Siri) too.

- **Pyto – Python IDE (ColdGrub1384)**: Python 3.10 IDE with NumPy/Matplotlib/Pandas, open-source. *Strengths:* Free, scientific libs included, supports external packages. *Weaknesses:* UI less polished. *Unique:* Can use `pip` within app, supports Siri Shortcuts. *Copy:* This as open-source inspiration for embedding a Python interpreter, enabling advanced computations and ML on-device.

- **Edge Cases and Labs**:  
  - **Nearby Interaction / UWB**: Check if iPhones can use U1 chip with NearbyInteraction. Apple’s NearbyInteraction framework can localize other U1 devices, might include a demo if available.  
  - **Shortcuts Gallery**: Many apps (Weather, Overcast, etc.) add Intents; we should research adding dozens of AppIntents.  
  - **open source libs**: Nordic’s iOS-BLE-Library provides Combine/Swift wrappers which could simplify our CoreBluetooth code. Home Assistant iOS repo shows MVVM structure with SwiftUI (2.2k stars).  
  - **Analytics**: If needed, consider adding performance benchmarks (FPS, latency) referencing Device Monitor’s approach.  

## Architecture and Modules  

**Overall Architecture:** We will use **Swift 6** and **SwiftUI** for UI, with Combine/async for concurrency. Follow MVVM: each feature/module has a View, ViewModel, and Service layer. Use **Dependency Injection** (e.g. via property wrappers or initializer injection) to mock services for testing. Organize features into separate Swift packages or frameworks (e.g. `SensorsKit`, `BLEKit`, `NetworkKit`, `AutomationKit`, `WidgetKit`). A **Plugin Architecture** can allow optional features (for example, a “Bluetooth Plugin” loaded only if user needs it). The UI layer will not directly access hardware; instead use **Services** (singletons or injected managers) that wrap frameworks. Use protocols to define interfaces for easy mocking. Document each module in markdown (or docc).  

**Core Modules:** Each iOS framework used will get its own section in design docs:

- **CoreBluetooth:** BLE central/peripheral roles. *Capabilities:* Scan, connect, read/write, advertise, notify. *Limitations:* Cannot discover classic BT (only BLE). *Permissions:* None (but background scanning requires `bluetooth-peripheral` background mode). *Privacy:* NO real privacy prompt, but use politely. *Docs:* Apple’s [CoreBluetooth](https://developer.apple.com/documentation/corebluetooth). *Future:* iOS may expand to more BLE features.  

- **CoreNFC:** NFC tag interactions. *Capabilities:* NDEF read/write (Type 1–5 tags). *Limitations:* No background scanning (except iOS 13+ allow NFC Triggers in shortcuts), no peer-to-peer, no card emulation. *Entitlement:* NFC Tag Reading. *Privacy:* iOS will prompt user when scanning NFC. *Docs:* [CoreNFC](https://developer.apple.com/documentation/corenfc). *Future:* iOS may add more support (not yet known).  

- **CoreLocation:** GPS, Compass, Geofence triggers. *Capabilities:* Location, heading, region monitoring. *Permissions:* Always or When-in-Use prompts. *Privacy:* Location usage prompt, explain in Info.plist. *Limitations:* Limited background time. *Docs:* [CoreLocation](https://developer.apple.com/documentation/corelocation).  

- **NearbyInteraction:** Use U1 chip for precise ranging. *Capabilities:* measure distance/bearing to another U1 device (requires both). *Limitations:* Only works with other iPhones or Apple devices with UWB. *Entitlement:* none extra, but requires user permission once. *Docs:* [NearbyInteraction](https://developer.apple.com/documentation/nearbyinteraction).  

- **Network.framework:** Low-level networking (NWPath, NWConnection, sockets). *Uses:* Custom TCP/UDP/MQTT/WebSockets. *Permissions:* None, but advanced features (like Packet Tunnel) require VPN entitlements. *Docs:* [Network](https://developer.apple.com/documentation/network). *Limitations:* Cannot capture other apps’ packets without special entitlements (Network Extension sandbox).  

- **CoreMotion:** Accelerometer, gyro, device motion updates. *Capabilities:* Orientation, activity, pedometer. *Permissions:* None for basic; Motion & Fitness entitlements for certain data on background. *Limitations:* Data rate ~100 Hz; background updates limited. *Docs:* [CoreMotion](https://developer.apple.com/documentation/coremotion).  

- **CoreHaptics:** Custom haptic patterns. *Capabilities:* Audio-haptics, sharpness/intensity control. *Limitations:* Only on devices with Taptic Engine (iPhone 8+). *Docs:* [Core Haptics](https://developer.apple.com/documentation/corehaptics).  

- **Vision / VisionKit:** Image analysis. *Capabilities:* Face/landmark recognition, text detection (OCR), barcode scanning, image classification, document scanning UI. *Permissions:* Camera usage for live scan; Photo Library to analyze stored images. *Docs:* [Vision](https://developer.apple.com/documentation/vision), [VisionKit](https://developer.apple.com/documentation/visionkit).  

- **ARKit:** (for depth/ambient). *Capabilities:* Scene depth, ambient light estimation (indirect). *Entitlement:* none, but `motion` and `camera`. *Use:* We might use ARKit only if needed for ambient light or advanced camera.  

- **AVFoundation:** Camera and microphone I/O. *Permissions:* Camera, Microphone usage prompts. *Capabilities:* Capture photo/video, microphone input levels. *Docs:* [AVFoundation](https://developer.apple.com/av-foundation).  

- **AudioKit / AudioToolbox:** Could use AudioKit for easy FFT/waveforms if allowed (AudioKit 5 is Swift-based). Or use AVAudioEngine + FFT. *Limitations:* Real-time audio processing has CPU cost.  

- **Speech:** Speech recognition to text. *Permission:* Microphone usage required. *Docs:* [Speech framework](https://developer.apple.com/documentation/speech).  

- **NaturalLanguage / CoreML:** For on-device NLP (language detection, sentiment) or running ML models. E.g. use Transformers via CoreML. *Privacy:* Possibly ask user about sensitive ML usage (not automatic, but mention it).  

- **WidgetKit / Live Activities:** Building widgets. *Use:* generate SwiftUI widget targets. *Limitations:* Widgets have fixed size and refresh rate constraints; Live Activities limited to short time. *Docs:* [WidgetKit](https://developer.apple.com/documentation/widgetkit), [ActivityKit](https://developer.apple.com/documentation/activitykit).  

- **AppIntents / SiriKit:** For exposing actions to Shortcuts. *Use:* define custom `AppIntent` and `AppShortcuts`. *Limitation:* Only iOS 16+. *Docs:* [AppIntents](https://developer.apple.com/documentation/appintents).  

- **BackgroundTasks:** Scheduling background refresh (limited to ~30s tasks). *Use:* Periodic sensor polling or network updates. *Docs:* [BackgroundTasks](https://developer.apple.com/documentation/backgroundtasks).  

- **Matter / HomeKit:** Although HomeKit was mentioned, we will mainly use it for appliance integration if we include home automation (but secondary). *Use:* Control HomeKit devices, if enabled. *Docs:* [HomeKit](https://developer.apple.com/documentation/homekit).  

- **CloudKit:** If we sync user templates or settings via iCloud. *Permission:* iCloud capability. *Docs:* [CloudKit](https://developer.apple.com/documentation/cloudkit).  

- **ExternalAccessory / FileProvider / DocumentBrowser:** To browse connected accessories (like BLE peripherals with MFi), or show files. Likely not high priority.  

- **MapKit:** If we provide maps (e.g. show location pins on widget). *Use:* optional.  

- **StoreKit:** Could be used for in-app purchases if we monetized features. For our research doc, mention: if using IAP, need StoreKit integration.  

- **CoreData/SwiftData:** For local storage of device data, history logs, user preferences. Probably SwiftData for future iOS.  

- **MultipeerConnectivity:** For peer-to-peer communication (e.g. mesh among iPhones). Could use to chat or transfer data (audio messages?). *Docs:* [MultipeerConnectivity].  

- **GameController:** Possibly for reading gamepad input (if a developer wants to test controllers). Niche, but mention.  

- **CoreTelephony:** Read cellular data info (carrier, signal strength). *Permission:* none, but `accessTelephony` if needed (private). Possibly skip.  

- **DeviceCheck:** Access device-specific data store (DCToken). Unlikely needed.  

- **AuthenticationServices:** Sign in with Apple or keychain access. *Use:* FaceID/TouchID to authorize actions.  

- **WebRTC:** If implementing video/audio chat (advanced). *Documentation:* [WebRTC for iOS].  

- **Bonjour/DNS-SD:** `NetServiceBrowser` for mDNS discovery. 

- **URLSession:** HTTP networking for REST/GraphQL.  

- **NetworkExtension:** (Research only) If wanting low-level packet capture or VPN, but requires special entitlements from Apple (likely not possible in sideload).  

- **DriverKit/Private APIs:** (Research only) We will not use private APIs (no jailbreak). DriverKit is for macOS drivers, not applicable to iOS apps.  

Every module will have documentation references (Apple Developer docs or major tutorials). For example, CoreNFC’s use is confirmed by articles.

## Sensor Dashboard Details  
- **Accelerometer/Gyro/Motion:** Use `CMMotionManager` for high-frequency accelerometer/gyro data; `CMMotionActivityManager` for activity. Data format: CMAcceleration (x,y,z), update interval up to ~100 Hz. *Automation:* e.g. trigger on shake or orientation. *Visualization:* Live 3D plot, arrow indicating orientation. *Shortcuts:* “Get current acceleration magnitude”.  

- **Magnetometer/Compass:** Use `CMMagnetometerData`; or `CLHeading` from CoreLocation for compass heading. *Refresh:* slower than accel, no permission. Visual: compass rose UI.  

- **Altimeter/Barometer:** Use `CMAltimeter`, available on devices with barometer (iPhone 6+). Provides relative altitude & pressure (in kPa). *Automation:* e.g. alert when pressure drops (storm). *Widget:* current altitude.  

- **GPS/Location:** CoreLocation’s `CLLocationManager` for latitude/longitude, horizontal accuracy. *Permissions:* always or in-use. *Refresh:* configurable distance/time filters. *Widget:* next event distance, current time zone.  

- **Heading:** `CLLocationManager.heading`. *Use:* digital compass.  

- **Battery & Charging:** `UIDevice.current.batteryLevel` and `batteryState`. *Permission:* none. *Automation:* detect low battery, switch modes. *Widget:* battery percentage; thermal state via `ProcessInfo.thermalState`.  

- **Thermal State:** `ProcessInfo.processInfo.thermalState` (nominal, fair, serious, critical). *UI:* color-coded bar.  

- **Orientation:** `UIDevice.current.orientation`. *Automation:* rotate UI.  

- **Ambient Light:** *No official API.* Possibly estimate via camera exposure level or ARKit’s ambientLightEstimate, but this is approximate. Document as “not directly available on iOS” and skip or use creative workarounds.  

- **Camera Metadata:** Use `AVCapturePhoto` metadata or `AVCaptureVideoDataOutput` for real-time (ISO, exposure, white balance). *Requires:* Camera permission.  

- **Microphone Levels:** `AVAudioRecorder` meter or `AVAudioEngine` input node tap. *Use:* display dB. *Permission:* Microphone.  

- **Face Detection:** Use Vision’s `VNDetectFaceRectanglesRequest` on camera frames. *Permission:* camera access.  

- **Proximity:** `UIDevice.current.isProximityMonitoringEnabled`. *Limitations:* only works when app is foreground and device close to ear. Rarely used.  

- **Screen:** `UIScreen.main.brightness`, `maximumFramesPerSecond`. *Use:* show display settings. *Always On Display:* iPhone 16e may have AOD; no public API, but we can consider brief mention.  

- **Audio Routing:** `AVAudioSession.sharedInstance().currentRoute`. *Show:* which output (speaker, headphone, BT).  

- **Memory/Storage:** Use `ProcessInfo.processInfo.physicalMemory` and `FileManager` to check free disk space (statfs). *Widget:* “free space indicator”.  

- **CPU Usage:** No public simple API. Possibly sample via Mach APIs (`task_info` CPU usage). *Caution:* may not be App Store allowed, but on sideload we might incorporate a simple sampling.  

- **Network Usage:** iOS does not expose per-app network usage to apps. We might track usage within the app only, or use NEFlow or private API (not recommended).  Possibly skip detailed network stats.  

- **Display Refresh Rate:** `UIScreen.main.maximumFramesPerSecond` (supports ProMotion). Show current vs max.  

- **Haptics:** Show which haptic motors available (standard vs iPhone with taptic). Possibly `CHHapticEngine.capabilitiesForHardware()`.  

- **Clock/Timezone/Locale:** `Date()`, `TimeZone.current`, `Locale.current`. Shortcuts: “Get current locale string.”  

- **Keyboard & Clipboard:** Keyboard events not public. Clipboard: `UIPasteboard.general.string`. Possibly show last copied text.

- **Live Activities / Dynamic Island:** On iOS 16+, activities can show on Lock Screen / Dynamic Island. We could allow creating a sample Live Activity from app intents (e.g. countdown, workout stats). Mention as future idea.

For each sensor/dashboard item, document any required plist keys (e.g. NSLocationAlwaysUsageDescription, NSCameraUsageDescription, etc.), the data update rates, and how to visualize (e.g. gauge, graph, map). Testing: verify sensors on simulator vs real device, handle missing sensor gracefully (iPhone without LiDAR, etc).

## Bluetooth Suite Details  
- **BLE Scanner**: Use `CBCentralManager` to scan (no permission prompt). Background scanning only with “Uses Bluetooth LE accessories” background mode; advertising is killed in background after few seconds. *Data:* CW->advertisementData as dictionary; parse manufacturer data manually (Eddystone/iBeacon beacons).
- **RSSI Graph:** Continuously update RSSI while scanning; use a simple line chart with values vs time. 
- **Service/Characteristic Explorer:** Once connected (`CBPeripheral`), call `discoverServices`, then `discoverCharacteristics`. Show each service/char in a tree view. 
- **Read/Write:** Allow text input for writing to a writable characteristic; offer hex toggle. 
- **Notifications:** Subscribe to NOTIFY char; display incoming data stream live. 
- **History & Export:** Log all interactions (timestamp, char UUID, data) to a file. Allow exporting via share sheet (text/CSV).
- **Saved Devices:** Maintain CoreData or UserDefaults list of discovered devices (by UUID) and custom names. 
- **ASCII/HEX Modes:** Input/output toggle. 
- **Packet Inspector:** For ADV packets, decode UUID, Major/Minor if iBeacon, TX power, device name. 
- **Automation:** Provide AppIntent “On BLE event, do X” triggers (where X could be a shortcut).
- **Shortcuts Actions:** E.g. “Scan for BLE service”, “Connect to BLE device”, “Send data to characteristic”. 
- **UI/UX:** Inspired by LightBlue and nRF Connect, use tabs or split view: one for scanning list (with filter bar), one for connection detail. 
- **User Story Example:** “As a developer, I want to explore a custom BLE sensor’s GATT table, so I can understand how to communicate with it from my code.”

*Technical Note:* CoreBluetooth callbacks are asynchronous on a background queue. We should encapsulate CB interactions in a Combine publisher or async interface for simplicity.

## NFC Suite Details  
- **Read NDEF:** Start `NFCNDEFReaderSession` on user tap. Requires presenting a system UI to scan. Show tag UID/type and parse any NDEF records (display text, URL, Wi-Fi config, etc). 
- **Write NDEF:** From iOS 13+, `NFCNDEFReaderSession` can also write (needs enabling in Info). Use `NFCNDEFWriterSession` to write text/URL from input. Limit to smaller payloads due to time. 
- **Tag Info:** Show tech list (ISO15693, MiFare, etc), memory size. Only if allowed by iOS (some needed proprietary commands may not be supported). 
- **History:** Save each scanned tag’s raw data (with timestamp) to CoreData. Provide a searchable history log. 
- **Import/Export:** Allow exporting a tag dump as .nfc (custom JSON) for later analysis. 
- **Known Database:** Ship a small offline DB of common tag UID->model (community data), so user can see if tag is known. 
- **Developer Tools:** Option to send low-level commands (only ISO15693 custom commands are possible). 
- **Limitations:** iOS won’t allow writing to some locked tags. Cannot emulate a card. Also, each session must be initiated by user (no continuous background scan). 
- **User Story:** “As a tester, I want to dump an NFC card’s data and share it with colleagues, so we can clone it on another device.” (We would allow exporting then re-writing on a clone tag using NXP TagWriter’s approach).
- **Shortcuts:** Use iOS 14’s “When NFC Tag is Scanned” automation for simple triggers. Also AppIntent actions like “Read NFC Tag” that returns content.

## Wi-Fi & Networking Suite Details  
- **Wi-Fi Info:** Use `CNCopyCurrentNetworkInfo` (deprecated) or `NEHotspotNetwork.fetchCurrent()` (with Entitlement: Access WiFi Information). Retrieves SSID/BSSID. Cannot get gateway via public APIs.
- **Ping/Traceroute:** Use BSD sockets (ICMP) or `SimplePing` library for ping. Traceroute via sending ICMP TTL-limited packets manually.
- **Port Scanner:** Attempt TCP connect on ports range (e.g. 1–1024) with timeout. *Warning:* scanning can trigger security warnings on enterprise networks. 
- **DNS Lookup:** Use `getaddrinfo` or `NWConnection` for custom DNS. 
- **SpeedTest:** Download/upload test (e.g. fetch a known file from speedtest.net or use Ookla API).
- **Bonjour/mDNS:** `NetServiceBrowser` to list local mDNS services. 
- **HTTP/REST Client:** Provide form to enter URL/headers/body, execute with `URLSession`, show JSON/text response. Similar to Postman. 
- **WebSocket:** `URLSessionWebSocketTask` to connect and send/receive. 
- **MQTT:** Integrate CocoaMQTT or similar to allow pub/sub. 
- **Local Network Discovery:** multicast ‘who is here’ via UDP broadcast, respond with device info. 
- **Wake on LAN:** Send UDP magic packet to a MAC broadcast (requires target’s MAC, can input).
- **QR Sharing:** Generate a QR that encodes current network SSID or device IP. 
- **Packet Log:** iOS cannot sniff Wi-Fi by app (no raw sockets in Apple sandbox).  
- **Network Monitor:** Show bytes used by this app (NSURLSessionTask metrics) – overall device network usage is private. We could approximate by monitoring our own requests.
- **Automation:** Conditions like “if ping fails” or “Wi-Fi SSID changes, then run shortcut.” Use Combine to monitor NWPath (`NWPathMonitor`) for connectivity changes.

## Camera Suite Details  
- **Live Camera Feed:** Using `AVCaptureSession`, show preview in SwiftUI via `UIViewRepresentable`.  
- **Frame Analysis:** Feed frames to Vision for on-device analysis (text, faces, objects). e.g. use `VNDetectBarcodesRequest` for QR. Use `VNCoreMLModel` for custom models.  
- **OCR/Barcode:** Implement on captured image or live via `VNRecognizeTextRequest` (VisionKitDemo shows how). Provide manual capture too.  
- **Document Scanning:** Invoke `VNDocumentCameraViewController` (VisionKit) to scan docs. It handles perspective correction and returns a UIImage; run OCR on it.  
- **Depth Info:** If LiDAR present, use `ARFrame.smoothedSceneDepth` or `AVCapturePhotoOutput` depthData. Display depth map intensity or measure object distance.  
- **Metadata:** Save photos and show Exif (GPS, timestamp, camera settings).  
- **RAW Capture:** `AVCapturePhotoOutput` with `isRawCaptureEnabled`; requires separate file. Provide basic preview of RAW (monochrome) or convert to TIFF.  
- **Image Pipeline:** Integrate `CoreImage.CIFilter` to allow filters on captured image. Could add an “Image Editor” tool for cropping, filters.  
- **Machine Learning:** Allow user to run any CoreML model on captured frame. For example, bundled ImageNet classifier or open tool to pick model.  
- **Automation:** e.g. on shaking phone, take photo and send to server.  
- **Shortcut:** “Get last photo metadata”, “Take photo and return file”, etc.  

## Audio Suite Details  
- **Input/Output Devices:** List `AVAudioSession` available inputs (built-in mic, headset) and outputs (speaker, AirPods). Allow user to switch.  
- **Routing:** Show and set audio route (to speaker/earpiece).  
- **Bluetooth Audio:** Indicate A2DP devices. Possibly display codec (AAC, etc) if available via private API.  
- **Spectrum Analyzer:** Use `AVAudioEngine` with a tap on input node; perform FFT to visualize frequency spectrum. (Waver’s “Spectrum” shows real-time audio frequencies.)  
- **Waveform:** Live waveform of mic input.  
- **Recording:** Record audio to file (`AVAudioRecorder`) with quality settings; playback.  
- **Streaming:** Create simple audio chat: use WebRTC (complex) or send via UDP (like a walkie-talkie mode). Possibly out of scope.  
- **Speech Recognition:** Use Apple Speech to transcribe microphone input to text.  
- **Text-to-Speech:** `AVSpeechSynthesizer` to speak text from keyboard or OCR results.  
- **Audio Terminal (Data over Sound):** Build “acoustic modem” mode. Inspired by *Waver*: send text messages via ultrasonic (inaudible) tones. Could incorporate Chirp-like protocol for short text; allow ultrasound/sonar signaling. Possibly limited by microphone/speaker response.  
- **Experimental:** Support audio unit processing (AUv3) so advanced users could write audio DSP plug-ins? (Complex, but we could leave a plugin slot.)  
- **Shortcuts:** e.g. “Record for N seconds and return text (speech-to-text)”.  

## Vibration & Haptics Suite  
- **Haptic Editor:** A visual timeline editor for CoreHaptics. As in *Haptic Pro*, allow placing events with custom intensity/sharpness. Real-time preview on device.  
- **Pattern Creation:** Manual and audio-driven. For audio, convert an imported file (MP3) into haptics (beats, dynamics, etc.) per Haptic Pro’s modes. Also support video-to-haptics (inspired by latest update in Haptic Pro).  
- **Presets & Library:** Provide a library of common patterns (single tap, double tap, success, error, notification types). Let users share patterns.  
- **Export:** Save as AHAP JSON or Swift code to integrate in their own apps. *Haptic Pro* can export ready-to-use Swift.  
- **Automation Hooks:** Trigger a custom haptic via Shortcut or in-app rule. E.g. “When receive a certain BLE notification, play pattern X.”  
- **Testing:** Visual graphs of waveform (like circles in Haptic Pro). Device vibrations can be felt by the user to fine-tune.  
- **UI:** Timeline similar to audio editors (zoomable), parameter sliders, playback controls.  

## Widget Studio Details  
- **Builder UI:** Drag UI elements (Text, Image, Chart, Button) onto a canvas (grid or free-form). Allow resizing. For data-bound widgets (charts, system stats), show live preview.  
- **Data Binding:** Users can create variables or pick sensor/API sources. For example, bind a label to “Current battery level”.  
- **Live sensor widgets:** Show real-time sensor data (accelerometer graph, compass needle).  
- **Buttons/Actions:** Buttons inside widget can trigger a Shortcut or an automation when tapped. (WidgetKit has limited interactivity; newer iOS allows a limited “URL” or `AppIntent` tap action.)  
- **Live Activities/Lock Screen:** Allow creating Live Activities which run in foreground or show on lock screen. For example, a countdown timer or workout stats.  
- **Templates & Community:** Include templates (toggles, charts, weather). Enable import via URL from others (like Widgy’s community share).  
- **Theme Engine:** Global settings for colors/fonts; ability to match widget color to system theme or user photo. (Widgetsmith included wallpaper theming.)  
- **Export/Import:** Widgets can be exported to iCloud or shared as JSON.  
- **WidgetKit Integration:** Each widget designed becomes an `IntentConfiguration` or `AppIntent`-driven widget. For complex logic, rely on AppIntents that our app provides.  
- **Offline Preview:** Show widget as it would appear on Home Screen.  
- **User Story:** “As a user, I want to build a custom Home Screen dashboard with real-time dev info (CPU use, network speed, BLE presence) using drag-and-drop, so I can monitor my device at a glance.”

## Shortcut Actions & AppIntents  
We will define a **massive set of AppIntent actions**. Example categories and actions:

- **Bluetooth:** Scan for peripherals, list saved devices, connect by name, read RSSI, write data, etc.  
- **NFC:** Read tag (return NDEF content), write tag (input text/URL), get last tag info.  
- **Camera:** Take photo, scan QR (read code), analyze image (e.g. “Recognize text in last photo”).  
- **Motion/Sensors:** Get accelerometer reading, start motion tracking, get battery level, get device orientation, get thermal state, etc.  
- **Audio:** Record voice memo for N seconds, transcribe speech, play phrase via TTS, get decibel level.  
- **Network:** Ping host, get current IP, scan Wi-Fi, run HTTP GET and return body, etc.  
- **Widgets:** Add a new widget (launch builder) or remove widget by identifier. (Limited but we can give shortcuts to open parts of app.)  
- **Variables & Text:** Convert units, encode/decode Base64/Hex/Regex replace, format JSON. (DevKit-like actions.)  
- **Files:** Read/write text file, list documents.  
- **Crypto:** Generate UUID, hash SHA256, encrypt/decrypt with key.  
- **QR/Barcode:** Generate QR image from text, decode QR from image.  
- **Diagnostics:** Crash reports viewer, toggle logging, get device info (model, OS).  
- **AI/ML:** Send prompt to ChatGPT (calls cloud) or to local model, summarization, image generation (if supported).  
- **Automation:** Trigger logging event, run another shortcut, speak text, vibrate pattern.  
- **Developer Tools:** Regex test (input regex & string, output matches), JSON path query, color converter RGB↔Hex, diff compare two texts.  

This acts as one of the largest Shortcuts providers. Each action will be documented with its parameters, return type, and example usage.

## Automation Engine Design  
- **Triggers:** Support time-based (cron-like schedules), location geofence, geohome/leaving, iBeacon/NFC tag, Bluetooth device connect/disconnect, device orientation change, incoming network webhook (with local ngrok), and manual.  
- **Conditions:** If-else logic on variables (sensor values, time of day, network status).  
- **Actions:** Any of the above shortcuts or custom blocks (run JS code, send HTTP request, show notification).  
- **Variables:** Global and flow-level. Typed (number, text, boolean, sensor values, JSON).  
- **UI:** Visual flowchart editor or rule list (IF X then Y). Could use a block-based interface (like Shortcuts app) inside our app for complex flows.  
- **Execution:** Use background task for scheduled triggers (BackgroundTasks API) where possible; or rely on Shortcuts app to run the Shortcut we create with conditions.  
- **Logging:** Show execution logs and errors.  
- **Example:** “When I arrive home (iBeacon or location), if battery < 20%, send myself a notification with the text ‘Charge me!’. Else turn on Bluetooth.”  
- **Testing:** Dry-run simulation mode to debug triggers/conditions.  

## Developer Tools Collection  
Include specialized developer utilities, for example:

- **JSON/YAML Viewer:** Pretty-print, query with JSONPath, convert.  
- **REST Client:** Reusable from above (with tabs), support OAuth or API keys.  
- **WebSocket Console:** connect to a ws server and send frames.  
- **MQTT Explorer:** connect to broker, subscribe to topics, publish messages.  
- **Regex Playground:** Real-time match visualization.  
- **JWT/Token Inspector:** Decode JWT header/payload, validate signature (with secret).  
- **Hex Editor/Binary Viewer:** Open any file and show hex dump.  
- **URL Tools:** Parse URL, percent-encode/decode, or query builder.  
- **Color Tools:** Color picker, converter (RGB/HSB/Hex), accessibility contrast checker.  
- **UUID Generator:** Random UUID v4.  
- **Hash/Encrypt:** Compute MD5/SHA1/SHA256; simple encrypt with password (AES) or encode.  
- **Secure Storage Browser:** View Keychain entries created by this app, or screenshot secure prefs (if allowed).  
- **JSON/XML Diff:** Show differences between two texts.  
- **Xcode Console Grabber:** (if using lib to fetch logs, or at least show our app’s logs).  
- **Crash Report Viewer:** For our app and maybe connected devices via Crashlytics (needs setup).  

We emulate tools found in *DevKit*, but also add network and file tools. Each tool is a small SwiftUI form + result view.

## AI Integration & ML  
- **Prompt Library:** Pre-built prompts for common tasks (code gen, query).  
- **Local Models:** Integrate CoreML models (e.g. GPT-type quantized model if feasible) or on-device LLM (Big Sur iPhone rumored to support neural inference?). Possibly use Apple’s new Neuron framework.  
- **Cloud Models:** If user supplies API keys, allow calling OpenAI/GPT4 or similar for code generation, JSON transformation, natural language to automation.  
- **Image Recognition:** Use Vision + CoreML to classify images. e.g. “label objects in photo”.  
- **Voice Assistant:** Use SiriKit or speech recognition with Wake Word (PocketSphinx etc) for voice commands.  
- **Automation Generation:** “Describe what you want and we create an automation flow.” Could call GPT to generate Shortcut sequences or Swift pseudocode.  
- **Testing AI:** Provide sandbox: user enters JSON, GPT returns transformed JSON; or user says “widget: show battery”, we generate SwiftUI code snippet.  
- **Privacy:** If using cloud, clearly disclose data use.  

## Security & Privacy Considerations  
List all **Permissions & Entitlements** required:  

- **NSBluetoothAlwaysUsageDescription** (Bluetooth scanning/advertising)  
- **NFCReaderUsageDescription** (NFC tag scans)  
- **NSCameraUsageDescription**, **NSPhotoLibraryUsageDescription** (camera and gallery)  
- **NSLocationWhenInUseUsageDescription**, **Always** (if using background geo)  
- **NSMicrophoneUsageDescription**, **Speech Recognition** (audio recording)  
- **UIBackgroundModes:** bluetooth-central, location, audio, fetch (as needed)  
- **Access WiFi Info** entitlement (to get SSID)  
- **HealthKit** (if any use of health data, for completeness)  
- **App Groups/Keychain Sharing** if we plan extensions.  

- **Keychain & Encryption:** Use CryptoKit for any symmetric encryption. Store secrets in Keychain (we might allow the user to store API keys or Wi-Fi passwords securely).  
- **Secure Enclave:** Possibly use for storing private keys or biometric locking (e.g. require Face ID to access certain dev tools).  
- **Privacy:** Ensure user data (sensor logs) is stored locally (not sent to server). No analytics.  
- **Sandboxing:** Aware that on iOS, we cannot read other apps’ data or use background execution except allowed.  
- **Threat Model:** Describe risks: The app is powerful, so if compromised, could leak device info. We should harden any network server (if we include remote connectivity) and validate any code or shortcuts input.  

## UI/UX Design  
We will create mockups and UI flows following HIG: clarity, direct manipulation, haptic feedback for actions. Key points:

- **Dashboard/Home:** Upon launch, show quick overview: Wi-Fi SSID, battery, top sensor readings, a mini console log. Like Home Assistant’s overview.  
- **Sidebar or Tabs:** Use a sidebar (on iPad) or tab bar (iPhone) to switch modules: “Dashboard, Sensors, Bluetooth, NFC, Network, Camera, Audio, Haptics, Widgets, Shortcuts, Tools, Automation, Settings”.  
- **Lists & Details:** Standard iOS lists for devices/services (e.g. BLE devices, Wi-Fi networks). Use context menus for common actions (copy, share).  
- **Charts & Graphs:** Use SwiftUI Charts for sensor graphs. Color-coded by value (e.g. green=OK, red=alert).  
- **Modals/Sheets:** For quick inputs (e.g. enter write data, JSON editor, code editor).  
- **Dark Mode:** Fully support dark theme; many tools have more impact in dark.  
- **Widgets within app:** For widget builder, use a canvas with drag handles. (Widgy’s real-time preview inspires our live design view.)  
- **Terminal UI:** For BLE text mode or WebSocket console, use monospace font with log-style view, input field at bottom.  
- **Settings:** Consolidate settings for permissions, caching, logs.  

We will gather inspiration from developer dashboards: e.g. Grafana’s panels (data visualization), Node-RED’s flow editor, VS Code’s command palette (maybe provide a quick “Spotlight-like” search in app for tools). We prioritize readability and quick access: e.g. “Copy response” buttons, one-tap actions.

## Data Flow and Folder Structure  
- **Folder Structure:**  
  - `App/` – main entry, global AppState, services.  
  - `Features/` – subfolders per feature (Sensors, BLE, NFC, Network, Camera, Audio, Haptics, Widgets, Shortcuts, Automation, Tools). Each contains MVVM files and SwiftUI Views.  
  - `Services/` – hardware access (BluetoothManager.swift, NFCTagManager.swift, LocationManager.swift, etc).  
  - `Models/` – data models (LogEntry, SensorData, DeviceInfo).  
  - `Views/Common/` – reusable SwiftUI views (Charts, Buttons, TextEditor).  
  - `Resources/` – Assets (icons, templates JSON, widget icons).  
  - `Tests/` – unit/UI test targets for critical modules.  
  - `.github/workflows/ci.yml` – GitHub Actions YAML.  

- **Data Flow:** Hardware layer emits data (sensors via Combine publishers, CoreBluetooth callbacks, network responses). Services process and store in ViewModels. Views observe ViewModels via `@ObservedObject`. Use Combine `@Published` or Swift Concurrency `@MainActor` async updates. Automations will listen to event publishers. All persistent data saved to CoreData or files as needed.

## Permissions & Entitlements  
- List all `Info.plist` keys and values (with rationale).  
- Describe how and when each permission is requested (on first use of feature).  
- Discuss that because we sideload, we have full control but should still respect user consent. For example, we won’t start Bluetooth scans unless in Bluetooth view.

## Implementation Phases & Milestones  
We will break development into phases, each delivering a working slice:  
1. **Core Architecture & Dev Tools**: Setup project, modular MVVM+DI structure. Implement basic DevKit-style tools (JSON, Base64, regex). Build Sensor Dashboard (static values: battery, device info).  
2. **Basic Connectivity**: BLE scanning and NFC read functionality. Demonstrate scanning UI. Integrate Home Assistant’s MVVM patterns from iOS repo for practices.  
3. **Network & Camera Modules**: Add network tools (ping, HTTP) and camera preview + simple analysis (barcode scan).  
4. **Automation & Shortcuts**: Implement first AppIntents and an automation trigger (e.g. time or location). Add Python/Lua/JS scripting support.  
5. **Haptics & Audio**: Add haptic editor UI and audio analysis.  
6. **Widget Builder**: Prototype widget drag/drop UI and example widget.  
7. **Refinement & CI**: Polish UI, caching, error handling. Finalize GitHub Actions (IPA build).  
8. **Testing & Security Audit**: Write tests, review entitlements, check privacy.  

Each milestone includes documentation for that part.

## GitHub Actions Workflow (build-ios-app.yml)  
```yaml
name: Build and Archive IPA

on:
  push:
    tags: [ 'v*' ]
  workflow_dispatch:

jobs:
  build:
    name: Build iOS App
    runs-on: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Xcode
        uses: maxim-lobanov/setup-xcode@v2
        with:
          xcode-version: '15.0'   # Xcode for iOS 16e

      - name: Install certificates and profiles
        env:
          BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
          P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
          PROVISION_PROFILE_BASE64: ${{ secrets.PROVISION_PROFILE_BASE64 }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Decode and install signing certificate
          echo "$BUILD_CERTIFICATE_BASE64" | base64 --decode > cert.p12
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security import cert.p12 -P "$P12_PASSWORD" -k build.keychain -T /usr/bin/codesign
          security list-keychain -d user -s build.keychain
          # Decode and install provisioning profile
          echo "$PROVISION_PROFILE_BASE64" | base64 --decode > profile.mobileprovision
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/

      - name: Build and Archive
        run: |
          xcodebuild -workspace "AppWorkspace.xcworkspace" \
            -scheme "UltimateToolKit" \
            -configuration Release \
            -destination "generic/platform=iOS" \
            -archivePath ${{ runner.temp }}/app.xcarchive \
            clean archive

      - name: Export IPA
        env:
          EXPORT_OPTIONS_PLIST: ${{ secrets.EXPORT_OPTIONS_PLIST }}
        run: |
          echo "$EXPORT_OPTIONS_PLIST" | base64 --decode > ExportOptions.plist
          xcodebuild -exportArchive \
            -archivePath ${{ runner.temp }}/app.xcarchive \
            -exportOptionsPlist ExportOptions.plist \
            -exportPath ${{ runner.temp }}/build

      - name: Upload IPA Artifact
        uses: actions/upload-artifact@v3
        with:
          name: UltimateToolKit.ipa
          path: ${{ runner.temp }}/build/UltimateToolKit.ipa
          retention-days: 7
```
This workflow uses **actions/checkout** and Xcode 15 to build and export the IPA. It decodes base64-encoded secrets (cert, profile) as shown in examples, creates a keychain, then runs `xcodebuild -archivePath`. Finally, it uses `actions/upload-artifact` to store the IPA. The secrets `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `PROVISION_PROFILE_BASE64`, and `EXPORT_OPTIONS_PLIST` must be configured in the repository.

## Testing Strategy  
- **Unit Tests:** Write tests for all utility functions (e.g. JSON parsing, BLE data parsing, cryptographic routines).  
- **UI Tests:** Use Xcode UI testing to verify basic flows: scanning a BLE device (simulate with MockManager), opening camera, filling forms, widget layout.  
- **Integration Tests:** For complex modules (Automation engine), create test scenarios and validate outputs.  
- **Manual Testing:** On real devices (especially for sensors, BLE, NFC) ensure each hardware feature works. Test on both iPhone and iPad.  
- **Continuous Integration:** Use GitHub Actions to run `xcodebuild test` on push. Use `DeviceLab` if available or try third-party emulators for multi-device testing.  
- **Risk & Mitigation:** Key risk is Apple rejecting our entitlements (though we sideload). Also heavy use of sensors may drain battery. We mitigate by efficient code (Swift Concurrency) and letting user disable modules. Another risk is compatibility with future iOS; we design to use public APIs and update as needed.

## Risk Analysis  
- **Platform Limits:** iOS restricts background access, raw hardware (no ambient light), and no arbitrary inter-process comms. Mitigation: design with these in mind, use Shortcuts and AppIntents for automation.  
- **Privacy & Security:** App has broad permissions; risk of data leak or malicious use. Mitigation: all data stays local, user consent required, encryption for sensitive info.  
- **Performance:** Many real-time sensors and networking could tax CPU/battery. Mitigation: use proper throttling (e.g. `.interval` for Location updates), low-power APIs (NWPathMonitor), and allow disabling unneeded features.  
- **Complexity:** Very broad feature set might become too complicated. Mitigation: modular design so advanced features can be hidden or toggled; careful UI design to avoid overwhelming user.  
- **API Changes:** Future iOS might alter frameworks (NetworkExtension changes, new Bluetooth stack). We will abstract hardware access behind services so adapting to OS changes is localized.

## Future Features & Stretch Goals  
- **Remote Server Companion:** A web interface or cloud sync to view device data remotely (similar to Home Assistant’s cloud).  
- **Scripting Console:** In-app REPL for Python/JS to allow ad-hoc commands.  
- **Plugin Support:** Allow third-party developers to add plugins (maybe via Swift Packages) for new hardware or integrations.  
- **Collaboration:** Sync automations/widgets with iCloud so they can be shared across devices.  
- **Accessibility:** VoiceOver support, large type, etc (comply with HIG).  
- **Machine-to-Machine:** Use Bluetooth Mesh (with appropriate libraries) for peer IoT communications.

## Developer Notes  
All code should be documented in-code (Swift docs) and this plan with citations. Follow Swift naming conventions. Avoid private APIs; if any needed (e.g. getting total RAM), mark as research only.

## References  
Key sources used in this research include:  
- DevKit App Store description  
- Network Analyzer features  
- Fing App Store description  
- Pythonista App Store  
- Scriptable App Store  
- AirPort Utility App Store  
- EXA Sensor Toolbox App  
- Device Monitor Z App  
- BLE Scanner App  
- NFC Tools App  
- nRF Connect App  
- LightBlue App  
- Home Assistant iOS App  
- IFTTT App  
- Waver (Data over Sound) App  
- Haptic Pro App  
- VisionKit Demo (Apple iOS 13 doc scanning)  
- Nordic iOS-BLE-Library (GitHub)  
- iSH Shell (App Store), and iSH GitHub  
- Pyto (GitHub)  
- Core NFC Apple docs via PunchThrough blog  
- GitHub Actions build example (Andrew Hoog)

*(End of plan.md)*