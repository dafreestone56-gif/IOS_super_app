import AVFoundation
import SwiftUI

struct AudioView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var phrase = ""
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
                    VStack(spacing: 0) {
                        tool("Waveform", "Live microphone level metering", "waveform")
                        tool("Spectrum", "FFT analyzer is prepared as the next audio layer", "chart.bar.xaxis")
                        tool("Recorder", "Recording foundation uses AVAudioRecorder", "record.circle")
                        tool("Speech to Text", "Speech framework hook is documented for device QA", "text.bubble")
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
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.vertical, 10)
    }
}
