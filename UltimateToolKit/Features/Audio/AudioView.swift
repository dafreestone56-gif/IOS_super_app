import AVFoundation
import SwiftUI

struct AudioView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var phrase = ""
    @State private var selectedTool = "Waveform"
    @State private var toolMessage = "Pick an audio tool to start working with live input or playback."
    private let speaker = AVSpeechSynthesizer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Audio Route", systemImage: "speaker.wave.2.fill")
                                .font(.headline)
                            Spacer()
                            Text(services.audio.routeDescription)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Text("Input: \(services.audio.inputDescription)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                        if services.audio.levels.isEmpty {
                            Text("Start monitoring to show microphone levels.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
                        } else {
                            Sparkline(values: services.audio.levels, tint: .indigo)
                                .frame(height: 72)
                                .padding(10)
                                .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
                        }
                        HStack {
                            Text("Level")
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text(String(format: "%.1f dBFS", services.audio.currentDecibels))
                                .foregroundStyle(.indigo)
                        }
                        .font(.caption)
                        Text("Microphone permission: \(services.audio.permissionStatus)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                HStack {
                    Button("Request Mic") {
                        services.audio.requestPermission()
                    }
                    .buttonStyle(.bordered)

                    Button(services.audio.isMonitoring ? "Stop Monitor" : "Start Monitor") {
                        if services.audio.isMonitoring {
                            services.audio.stopMetering()
                            services.log("Audio monitor stopped")
                        } else {
                            services.audio.startMetering()
                            services.log("Audio monitor started")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                SectionLabel(title: "Recorder")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(services.audio.lastRecordingName)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Button {
                            let result = services.audio.playLastRecording()
                            services.log(result)
                        } label: {
                            Label("Play Last Recording", systemImage: "play.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SectionLabel(title: "Speech")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Phrase", text: $phrase)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                        Button {
                            speak()
                        } label: {
                            Label("Speak", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                SectionLabel(title: "Tools")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        tool("Waveform", "Live microphone level metering", "waveform")
                        tool("Spectrum", "Live level-band analyzer from microphone input", "chart.bar.xaxis")
                        tool("Recorder", "Records CAF files into app documents", "record.circle")
                        tool("Speech", "Speak typed phrases through AVSpeechSynthesizer", "text.bubble")
                        audioToolPanel
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Audio")
        .toolkitScreen()
        .onAppear {
            services.audio.refreshRoute()
        }
        .onDisappear {
            services.audio.stopMetering()
        }
    }

    private func speak() {
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speaker.speak(utterance)
        services.log("Text-to-speech played")
    }

    private func tool(_ title: String, _ subtitle: String, _ symbol: String) -> some View {
        Button {
            selectedTool = title
            runTool(title)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .foregroundStyle(.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: selectedTool == title ? "checkmark.circle.fill" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(selectedTool == title ? .green : AppTheme.tertiaryText)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var audioToolPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(toolMessage)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)

            switch selectedTool {
            case "Spectrum":
                AudioSpectrumBars(values: services.audio.levels)
                    .frame(height: 84)
            case "Recorder":
                HStack {
                    Button {
                        if services.audio.isMonitoring {
                            services.audio.stopMetering()
                            toolMessage = "Recording stopped. \(services.audio.lastRecordingName)"
                        } else {
                            services.audio.startMetering()
                            toolMessage = "Recording and metering started."
                        }
                    } label: {
                        Label(services.audio.isMonitoring ? "Stop Recording" : "Start Recording", systemImage: services.audio.isMonitoring ? "stop.fill" : "record.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        let result = services.audio.playLastRecording()
                        toolMessage = result
                        services.log(result)
                    } label: {
                        Label("Play Last", systemImage: "play.circle")
                    }
                    .buttonStyle(.bordered)
                }
            case "Speech":
                Button {
                    speak()
                } label: {
                    Label("Speak Phrase", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            default:
                Button {
                    if services.audio.isMonitoring {
                        services.audio.stopMetering()
                        toolMessage = "Waveform monitor stopped."
                    } else {
                        services.audio.startMetering()
                        toolMessage = "Waveform monitor started."
                    }
                } label: {
                    Label(services.audio.isMonitoring ? "Stop Waveform" : "Start Waveform", systemImage: services.audio.isMonitoring ? "stop.fill" : "waveform")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
    }

    private func runTool(_ title: String) {
        switch title {
        case "Waveform":
            if !services.audio.isMonitoring {
                services.audio.startMetering()
            }
            toolMessage = "Waveform monitor is reading live microphone levels."
        case "Spectrum":
            if !services.audio.isMonitoring {
                services.audio.startMetering()
            }
            toolMessage = "Spectrum view is showing live level bands from the microphone meter."
        case "Recorder":
            toolMessage = services.audio.isMonitoring ? "Recording is active." : "Start a recording to capture a CAF file."
        case "Speech":
            toolMessage = "Type a phrase above, then use Speak Phrase."
        default:
            toolMessage = "Tool selected."
        }
        services.log("Audio tool selected: \(title)")
    }
}

private struct AudioSpectrumBars: View {
    let values: [Double]

    private var bands: [Double] {
        let safe = Array(values.filter { $0.isFinite }.suffix(24))
        guard !safe.isEmpty else { return Array(repeating: 0.08, count: 12) }
        return (0..<12).map { index in
            let sample = safe[index % safe.count]
            let shaped = min(1, max(0.04, sample * (0.72 + Double(index % 4) * 0.12)))
            return shaped
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(bands.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.indigo.opacity(0.28 + value * 0.62))
                    .frame(maxWidth: .infinity)
                    .frame(height: 12 + CGFloat(value) * 68)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
    }
}
