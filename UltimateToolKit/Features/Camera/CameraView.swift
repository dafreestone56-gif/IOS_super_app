import AVFoundation
import SwiftUI
import UIKit
import Vision

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
                .onChange(of: analysisMode) { _, newValue in
                    camera.analysisMode = newValue
                    services.log("Camera analysis mode changed to \(newValue)")
                }

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

                if !camera.detectedText.isEmpty {
                    SectionLabel(title: "Detected Text")
                    GlassPanel {
                        Text(camera.detectedText)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if !camera.detectedFaces.isEmpty {
                    SectionLabel(title: "Detected Faces")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(camera.detectedFaces, id: \.self) { face in
                                Text(face)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if !camera.capturedPhotoSummary.isEmpty {
                    SectionLabel(title: "Last Capture")
                    GlassPanel {
                        Text(camera.capturedPhotoSummary)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                SectionLabel(title: "Vision Tools")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            camera.capturePhoto()
                            services.log("Photo capture requested")
                        } label: {
                            Label("Capture Photo Metadata", systemImage: "camera.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!camera.isRunning)
                        tool("QR / Barcode", "Live metadata scanner", "qrcode.viewfinder")
                        tool("OCR", "Live text recognition from frames", "text.viewfinder")
                        tool("Faces", "Live face rectangle detection", "face.smiling")
                        tool("Metadata", "Photo size and metadata keys on capture", "info.circle")
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
        case .authorized: return camera.isRunning ? "Camera preview running" : "Camera access authorized"
        case .denied: return "Camera access denied"
        case .restricted: return "Camera access restricted"
        case .notDetermined: return "Camera permission not requested"
        @unknown default: return "Camera status unknown"
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
        camera.analysisMode = analysisMode
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

final class CameraPreviewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var detectedCodes: [String] = []
    @Published private(set) var detectedText = ""
    @Published private(set) var detectedFaces: [String] = []
    @Published private(set) var capturedPhotoSummary = ""
    var analysisMode = "QR / Barcode"

    private let queue = DispatchQueue(label: "ToolkitCameraSession")
    private let videoQueue = DispatchQueue(label: "ToolkitCameraVision")
    private let photoOutput = AVCapturePhotoOutput()
    private var configured = false
    private var lastVisionAnalysis = Date.distantPast

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
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(self, queue: self.videoQueue)
                if self.session.canAddOutput(videoOutput) {
                    self.session.addOutput(videoOutput)
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

    func capturePhoto() {
        queue.async {
            guard self.configured else { return }
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
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

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard ["OCR", "Faces"].contains(analysisMode) else { return }
        guard Date().timeIntervalSince(lastVisionAnalysis) > 0.8 else { return }
        lastVisionAnalysis = Date()
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        if analysisMode == "OCR" {
            let request = VNRecognizeTextRequest { [weak self] request, error in
                let lines = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                DispatchQueue.main.async {
                    if let error {
                        self?.errorMessage = error.localizedDescription
                    } else if !lines.isEmpty {
                        self?.detectedText = lines.prefix(12).joined(separator: "\n")
                    }
                }
            }
            request.recognitionLevel = .fast
            try? handler.perform([request])
        } else if analysisMode == "Faces" {
            let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
                let faces = (request.results as? [VNFaceObservation]) ?? []
                DispatchQueue.main.async {
                    if let error {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.detectedFaces = faces.enumerated().map { index, face in
                            let box = face.boundingBox
                            return String(format: "Face %d  x %.2f  y %.2f  w %.2f  h %.2f", index + 1, box.origin.x, box.origin.y, box.width, box.height)
                        }
                    }
                }
            }
            try? handler.perform([request])
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            return
        }
        let data = photo.fileDataRepresentation() ?? Data()
        let image = UIImage(data: data)
        let size = image.map { "\(Int($0.size.width)) x \(Int($0.size.height)) px" } ?? "Unknown size"
        let metadataKeys = photo.metadata.keys.sorted().joined(separator: ", ")
        DispatchQueue.main.async {
            self.capturedPhotoSummary = """
            Size: \(size)
            Bytes: \(data.count)
            Metadata keys: \(metadataKeys)
            """
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
