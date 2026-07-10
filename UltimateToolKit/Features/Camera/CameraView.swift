import AVFoundation
import SwiftUI
import UIKit

struct CameraView: View {
    @EnvironmentObject private var services: ToolkitServices
    @StateObject private var camera = CameraPreviewModel()
    @State private var permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var analysisMode = "QR / Barcode"

    private let modes = ["QR / Barcode", "OCR", "Faces", "Metadata"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.largeTitle)
                            .foregroundStyle(.cyan)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Camera Suite")
                                .font(.headline)
                            Text(permissionText)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Button(permissionStatus == .authorized ? "Start" : "Request") {
                            permissionStatus == .authorized ? startCamera() : requestCamera()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Picker("Analysis", selection: $analysisMode) {
                    ForEach(modes, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)

                ZStack {
                    if permissionStatus == .authorized {
                        CameraPreview(session: camera.session)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.58))
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.cyan)
                            Text("Camera permission required")
                                .font(.headline)
                            Text("Grant access to test live preview, QR scanning, OCR, and Vision workflows.")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppTheme.secondaryText)
                                .padding(.horizontal)
                        }
                    }
                }
                .frame(height: 320)

                if let error = camera.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8))
                }

                if !camera.detectedCodes.isEmpty {
                    SectionLabel(title: "Detected Codes")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(camera.detectedCodes, id: \.self) { code in
                                Text(code)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                SectionLabel(title: "Vision Tools")
                GlassPanel {
                    VStack(spacing: 0) {
                        tool("QR / Barcode", "Vision barcode request", "qrcode.viewfinder")
                        tool("OCR", "Recognize text in frames or images", "text.viewfinder")
                        tool("Faces", "Detect face rectangles and landmarks", "face.smiling")
                        tool("Document Scan", "VisionKit document scanner", "doc.viewfinder")
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Camera")
        .toolkitScreen()
        .onDisappear { camera.stop() }
    }

    private var permissionText: String {
        switch permissionStatus {
        case .authorized: camera.isRunning ? "Camera preview running" : "Camera access authorized"
        case .denied: "Camera access denied"
        case .restricted: "Camera access restricted"
        case .notDetermined: "Camera permission not requested"
        @unknown default: "Camera status unknown"
        }
    }

    private func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
                services.log(granted ? "Camera permission granted" : "Camera permission denied")
                if granted {
                    startCamera()
                }
            }
        }
    }

    private func startCamera() {
        camera.configureIfNeeded()
        camera.start()
        services.log("Camera preview started")
    }

    private func tool(_ title: String, _ subtitle: String, _ symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.cyan)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.vertical, 10)
    }
}

final class CameraPreviewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var detectedCodes: [String] = []

    private let queue = DispatchQueue(label: "ToolkitCameraSession")
    private var configured = false

    func configureIfNeeded() {
        guard !configured else { return }
        queue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            defer {
                self.session.commitConfiguration()
            }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async { self.errorMessage = "No back camera is available." }
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard self.session.canAddInput(input) else {
                    DispatchQueue.main.async { self.errorMessage = "Cannot add camera input." }
                    return
                }
                self.session.addInput(input)
                let metadataOutput = AVCaptureMetadataOutput()
                if self.session.canAddOutput(metadataOutput) {
                    self.session.addOutput(metadataOutput)
                    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes.filter {
                        [.qr, .ean8, .ean13, .code128, .pdf417, .aztec, .dataMatrix].contains($0)
                    }
                }
                self.configured = true
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
        }
    }

    func start() {
        queue.async {
            guard self.configured, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        queue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        let codes = metadataObjects.compactMap { object -> String? in
            guard let readable = object as? AVMetadataMachineReadableCodeObject else { return nil }
            return readable.stringValue
        }
        if !codes.isEmpty {
            detectedCodes = Array(Set(codes)).sorted()
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
