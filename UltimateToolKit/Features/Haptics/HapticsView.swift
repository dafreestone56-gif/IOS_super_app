import CoreHaptics
import SwiftUI
import UIKit

struct HapticsView: View {
    @EnvironmentObject private var services: ToolkitServices
    @StateObject private var player = HapticPatternPlayer()
    @State private var intensity = 0.75
    @State private var sharpness = 0.45
    @State private var sequenceName = "Toolkit Pulse"
    @State private var steps: [HapticStep] = [
        HapticStep(delay: 0, intensity: 0.75, sharpness: 0.45),
        HapticStep(delay: 0.16, intensity: 0.45, sharpness: 0.2),
        HapticStep(delay: 0.18, intensity: 0.95, sharpness: 0.8)
    ]
    @State private var savedSequences: [SavedHapticSequence] = AppPersistence.load([SavedHapticSequence].self, key: "haptic.sequences", fallback: [])
    @State private var exportedAHAP = ""

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
                        Button {
                            playSequence()
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Sequence name", text: $sequenceName)
                            .textInputAutocapitalization(.words)
                            .padding(10)
                            .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))

                        slider("Preview Intensity", value: $intensity)
                        slider("Preview Sharpness", value: $sharpness)

                        HStack {
                            Button {
                                steps.append(HapticStep(delay: 0.14, intensity: intensity, sharpness: sharpness))
                                services.log("Haptic step added")
                            } label: {
                                Label("Add Step", systemImage: "plus")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                player.play(intensity: Float(intensity), sharpness: Float(sharpness))
                                services.log("Single haptic preview played")
                            } label: {
                                Label("Tap", systemImage: "hand.tap")
                            }
                            .buttonStyle(.bordered)
                        }

                        sequenceTimeline
                    }
                }

                SectionLabel(title: "Sequence Steps")
                GlassPanel {
                    VStack(spacing: 12) {
                        ForEach($steps) { stepBinding in
                            HapticStepEditor(step: stepBinding) {
                                let id = stepBinding.wrappedValue.id
                                steps.removeAll { $0.id == id }
                            }
                            Divider().background(AppTheme.hairline)
                        }
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button {
                                saveSequence()
                            } label: {
                                Label("Save Sequence", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(steps.isEmpty)

                            Button {
                                exportedAHAP = HapticPatternPlayer.ahapJSON(steps: steps)
                                services.log("Sequence AHAP exported")
                            } label: {
                                Label("Export AHAP", systemImage: "doc.badge.gearshape")
                            }
                            .buttonStyle(.bordered)
                        }

                        if !exportedAHAP.isEmpty {
                            Button {
                                UIPasteboard.general.string = exportedAHAP
                                services.log("Sequence AHAP copied")
                            } label: {
                                Label("Copy AHAP", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            Text(exportedAHAP)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                SectionLabel(title: "Saved Sequences")
                GlassPanel {
                    VStack(spacing: 0) {
                        if savedSequences.isEmpty {
                            Text("Saved patterns will appear in Shortcuts as named sequences.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(savedSequences) { sequence in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(sequence.name)
                                        Text("\(sequence.steps.count) steps  Updated \(sequence.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    Button {
                                        load(sequence)
                                    } label: {
                                        Image(systemName: "slider.horizontal.3")
                                    }
                                    .buttonStyle(.bordered)
                                    Button {
                                        player.play(sequence: sequence)
                                        services.log("Saved haptic sequence played: \(sequence.name)")
                                    } label: {
                                        Image(systemName: "play.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    Button(role: .destructive) {
                                        savedSequences.removeAll { $0.id == sequence.id }
                                        AppPersistence.save(savedSequences, key: "haptic.sequences")
                                        services.log("Saved haptic sequence deleted: \(sequence.name)")
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.vertical, 10)
                                Divider().background(AppTheme.hairline)
                            }
                        }
                    }
                }

                SectionLabel(title: "Presets")
                GlassPanel {
                    VStack(spacing: 0) {
                        preset("Success", "notification success", .green, [
                            HapticStep(delay: 0, intensity: 0.65, sharpness: 0.35),
                            HapticStep(delay: 0.12, intensity: 0.9, sharpness: 0.6)
                        ])
                        preset("Warning", "notification warning", .orange, [
                            HapticStep(delay: 0, intensity: 0.85, sharpness: 0.75),
                            HapticStep(delay: 0.22, intensity: 0.7, sharpness: 0.3)
                        ])
                        preset("Error", "notification error", .red, [
                            HapticStep(delay: 0, intensity: 1, sharpness: 0.9),
                            HapticStep(delay: 0.15, intensity: 1, sharpness: 0.9),
                            HapticStep(delay: 0.15, intensity: 0.8, sharpness: 0.6)
                        ])
                        preset("Rigid Tap", "impact rigid", .purple, [
                            HapticStep(delay: 0, intensity: 1, sharpness: 1)
                        ])
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Haptics")
        .toolkitScreen()
    }

    private var sequenceTimeline: some View {
        HStack(alignment: .bottom, spacing: 7) {
            ForEach(steps) { step in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.purple.opacity(0.22 + min(0.7, step.intensity * 0.7)))
                    .frame(width: max(12, 14 + step.delay * 65), height: CGFloat(20 + step.intensity * 62))
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(Color.white.opacity(0.32 + step.sharpness * 0.45))
                            .frame(height: 4)
                    }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .bottomLeading)
        .padding(10)
        .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 8))
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

    private func preset(_ title: String, _ subtitle: String, _ tint: Color, _ presetSteps: [HapticStep]) -> some View {
        Button {
            sequenceName = title
            steps = presetSteps
            player.play(steps: presetSteps)
            services.log("Haptic preset loaded: \(title)")
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

    private func playSequence() {
        player.play(steps: steps)
        services.log("Haptic sequence played with \(steps.count) step(s)")
    }

    private func saveSequence() {
        let cleanName = sequenceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sequence = SavedHapticSequence(
            name: cleanName.isEmpty ? "Untitled Sequence" : cleanName,
            steps: steps,
            updatedAt: Date()
        )
        savedSequences.removeAll { $0.name.caseInsensitiveCompare(sequence.name) == .orderedSame }
        savedSequences.insert(sequence, at: 0)
        savedSequences = Array(savedSequences.prefix(50))
        AppPersistence.save(savedSequences, key: "haptic.sequences")
        services.log("Haptic sequence saved for Shortcuts: \(sequence.name)")
    }

    private func load(_ sequence: SavedHapticSequence) {
        sequenceName = sequence.name
        steps = sequence.steps
        services.log("Haptic sequence loaded: \(sequence.name)")
    }
}

private struct HapticStepEditor: View {
    @Binding var step: HapticStep
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Step", systemImage: "waveform.path")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
            valueSlider("Delay", value: $step.delay, range: 0...1.5, format: "%.2fs")
            valueSlider("Intensity", value: $step.intensity, range: 0...1, format: "%.2f")
            valueSlider("Sharpness", value: $step.sharpness, range: 0...1, format: "%.2f")
        }
        .padding(.vertical, 4)
    }

    private func valueSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Slider(value: value, in: range)
        }
    }
}

final class HapticPatternPlayer: ObservableObject {
    private var engine: CHHapticEngine?

    func play(intensity: Float, sharpness: Float) {
        play(steps: [HapticStep(delay: 0, intensity: Double(intensity), sharpness: Double(sharpness))])
    }

    func play(sequence: SavedHapticSequence) {
        play(steps: sequence.steps)
    }

    func play(steps: [HapticStep]) {
        let safeSteps = steps.isEmpty ? [HapticStep(delay: 0, intensity: 0.7, sharpness: 0.4)] : steps
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playFallback(steps: safeSteps)
            return
        }

        do {
            if engine == nil {
                engine = try CHHapticEngine()
            }
            try engine?.start()
            var currentTime = 0.0
            let events = safeSteps.map { step -> CHHapticEvent in
                currentTime += max(0, step.delay)
                return CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(min(1, max(0, step.intensity)))),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(min(1, max(0, step.sharpness))))
                    ],
                    relativeTime: currentTime
                )
            }
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let patternPlayer = try engine?.makePlayer(with: pattern)
            try patternPlayer?.start(atTime: 0)
        } catch {
            playFallback(steps: safeSteps)
        }
    }

    static func ahapJSON(intensity: Float, sharpness: Float) -> String {
        ahapJSON(steps: [HapticStep(delay: 0, intensity: Double(intensity), sharpness: Double(sharpness))])
    }

    static func ahapJSON(steps: [HapticStep]) -> String {
        var currentTime = 0.0
        let pattern = steps.map { step -> [String: Any] in
            currentTime += max(0, step.delay)
            return [
                "Event": [
                    "Time": currentTime,
                    "EventType": "HapticTransient",
                    "EventParameters": [
                        ["ParameterID": "HapticIntensity", "ParameterValue": min(1, max(0, step.intensity))],
                        ["ParameterID": "HapticSharpness", "ParameterValue": min(1, max(0, step.sharpness))]
                    ]
                ]
            ]
        }
        let payload: [String: Any] = [
            "Version": 1.0,
            "Pattern": pattern
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]) else {
            return "{}"
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func playFallback(steps: [HapticStep]) {
        var delay = 0.0
        for step in steps {
            delay += max(0, step.delay)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred(intensity: CGFloat(min(1, max(0, step.intensity))))
            }
        }
    }
}
