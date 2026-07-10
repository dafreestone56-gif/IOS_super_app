import CoreHaptics
import SwiftUI
import UIKit

struct HapticsView: View {
    @EnvironmentObject private var services: ToolkitServices
    @StateObject private var player = HapticPatternPlayer()
    @State private var intensity = 0.75
    @State private var sharpness = 0.45

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassPanel {
                    HStack(spacing: 12) {
                        Image(systemName: "circle.hexagongrid.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Haptic Editor")
                                .font(.headline)
                            Text(CHHapticEngine.capabilitiesForHardware().supportsHaptics ? "CoreHaptics supported" : "Advanced haptics unavailable")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Button("Play") { playPreview() }
                            .buttonStyle(.borderedProminent)
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        slider("Intensity", value: $intensity)
                        slider("Sharpness", value: $sharpness)
                        timeline
                    }
                }

                SectionLabel(title: "Presets")
                GlassPanel {
                    VStack(spacing: 0) {
                        preset("Success", "notification success", .green)
                        preset("Warning", "notification warning", .orange)
                        preset("Error", "notification error", .red)
                        preset("Rigid Tap", "impact rigid", .purple)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Haptics")
        .toolkitScreen()
    }

    private var timeline: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<18, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.purple.opacity(0.35 + Double(index % 5) * 0.11))
                    .frame(height: CGFloat(18 + (index % 5) * 10))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func slider(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Slider(value: value, in: 0...1)
        }
    }

    private func preset(_ title: String, _ subtitle: String, _ tint: Color) -> some View {
        Button {
            playPreview()
        } label: {
            HStack {
                Image(systemName: "waveform.path")
                    .foregroundStyle(tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func playPreview() {
        player.play(intensity: Float(intensity), sharpness: Float(sharpness))
        services.log("Haptic pattern played")
    }
}

final class HapticPatternPlayer: ObservableObject {
    private var engine: CHHapticEngine?

    func play(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            return
        }

        do {
            if engine == nil {
                engine = try CHHapticEngine()
            }
            try engine?.start()
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let patternPlayer = try engine?.makePlayer(with: pattern)
            try patternPlayer?.start(atTime: 0)
        } catch {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }
    }
}
