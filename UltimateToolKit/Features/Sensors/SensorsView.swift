import SwiftUI

struct SensorsView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var filter = "All"

    private let filters = ["All", "Motion", "Environment", "Device"]

    private var visibleMetrics: [SensorMetric] {
        switch filter {
        case "Motion":
            services.sensors.metrics.filter { ["Accelerometer", "Gyroscope", "Orientation"].contains($0.title) }
        case "Environment":
            services.sensors.metrics.filter { ["Thermal State", "Display"].contains($0.title) }
        case "Device":
            services.sensors.metrics.filter { ["Battery", "Memory", "Storage"].contains($0.title) }
        default:
            services.sensors.metrics
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("Filter", selection: $filter) {
                    ForEach(filters, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)

                ForEach(visibleMetrics) { metric in
                    MetricCard(metric: metric)
                }

                GlassPanel {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Export")
                                .font(.headline)
                            Text("Export the current live sensor snapshot as CSV text to the event log.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Button("Log") {
                            services.log(services.sensors.exportCSV())
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Sensors")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { services.sensors.start() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .toolkitScreen()
        .onAppear { services.sensors.start() }
    }
}
