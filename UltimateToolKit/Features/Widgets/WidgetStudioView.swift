import SwiftUI

struct WidgetStudioView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var cornerRadius = 16.0
    @State private var theme = "System"
    @State private var background = "Blur"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                widgetPreview

                SectionLabel(title: "Add Component")
                GlassPanel {
                    HStack(spacing: 10) {
                        componentButton("Text", "textformat")
                        componentButton("Gauge", "gauge.with.dots.needle.67percent")
                        componentButton("Chart", "chart.xyaxis.line")
                        componentButton("Sensor", "waveform.path.ecg")
                        componentButton("Image", "photo")
                    }
                }

                GlassPanel {
                    VStack(spacing: 16) {
                        settingRow("Theme", theme)
                        settingRow("Background", background)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Corner Radius")
                                Spacer()
                                Text(Int(cornerRadius).description)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Slider(value: $cornerRadius, in: 0...28, step: 1)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Widget Studio")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { services.log("Widget template saved") } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
        .toolkitScreen()
        .onAppear {
            services.sensors.start()
            services.network.refreshInterfaces()
        }
    }

    private var widgetPreview: some View {
        let battery = metricValue("Battery")
        let thermal = metricValue("Thermal State")
        let storage = metricValue("Storage")
        let wifi = services.network.status
        let trend = services.sensors.metrics.first(where: { $0.title == "Battery" })?.trend ?? []

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(.green.opacity(0.25), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: batteryFraction)
                        .stroke(.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "battery.100percent")
                        .foregroundStyle(.green)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading) {
                    Text("Battery")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(battery)
                        .font(.title.bold())
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Thermal")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(thermal)
                        .font(.headline)
                    Sparkline(values: trend, tint: .green)
                        .frame(width: 96, height: 28)
                }
            }

            HStack(spacing: 8) {
                smallWidgetMetric("Sensors", "\(services.sensors.metrics.count)", "waveform.path.ecg")
                smallWidgetMetric("Network", wifi, "wifi")
                smallWidgetMetric("Storage", storage, "internaldrive")
                smallWidgetMetric("Interfaces", "\(services.network.activeInterfaces.count)", "network")
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(AppTheme.hairline))
    }

    private func smallWidgetMetric(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(.blue)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
    }

    private func componentButton(_ title: String, _ symbol: String) -> some View {
        Button {
            services.log("Widget component added: \(title)")
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.headline)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
    }

    private func settingRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(AppTheme.secondaryText)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
    }

    private func metricValue(_ title: String) -> String {
        services.sensors.metrics.first(where: { $0.title == title })?.value ?? "--"
    }

    private var batteryFraction: Double {
        let raw = metricValue("Battery").replacingOccurrences(of: "%", with: "")
        return min(1, max(0, (Double(raw) ?? 0) / 100))
    }
}
