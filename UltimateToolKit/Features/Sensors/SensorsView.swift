import SwiftUI

struct SensorsView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var filter = "All"
    @State private var selectedSensors: Set<String> = ["Accelerometer", "Gyroscope", "Magnetometer", "Barometer"]

    private let filters = ["All", "Motion", "Environment", "Device"]

    private var visibleMetrics: [SensorMetric] {
        switch filter {
        case "Motion":
            return services.sensors.metrics.filter { ["Accelerometer", "Gyroscope", "Magnetometer", "Device Motion", "Heading", "Orientation"].contains($0.title) }
        case "Environment":
            return services.sensors.metrics.filter { ["Thermal State", "Barometer", "Display", "Proximity"].contains($0.title) }
        case "Device":
            return services.sensors.metrics.filter { ["Battery", "Memory", "Storage", "Location"].contains($0.title) }
        default:
            return services.sensors.metrics
        }
    }

    private var graphableMetrics: [SensorMetric] {
        services.sensors.metrics.filter { !$0.trend.isEmpty }
    }

    private var selectedGraphMetrics: [SensorMetric] {
        let matches = graphableMetrics.filter { selectedSensors.contains($0.title) }
        return matches.isEmpty ? Array(graphableMetrics.prefix(2)) : matches
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("Filter", selection: $filter) {
                    ForEach(filters, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)

                loggingPanel

                sensorSelectionPanel

                ForEach(selectedGraphMetrics) { metric in
                    DetailedSensorGraph(
                        metric: metric,
                        samples: services.sensors.samples(for: metric.title),
                        isLogging: services.sensors.isLogging
                    )
                }

                ForEach(visibleMetrics) { metric in
                    MetricCard(metric: metric)
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Location and Heading")
                                    .font(.headline)
                                Text("Authorization: \(services.sensors.locationAuthorization)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Spacer()
                            Button {
                                services.sensors.requestLocationAccess()
                                services.log("Location access requested from Sensors")
                            } label: {
                                Label("Request", systemImage: "location.circle")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                exportPanel
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
        .onAppear {
            services.sensors.start()
        }
    }

    private var loggingPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: services.sensors.isLogging ? "record.circle.fill" : "record.circle")
                        .font(.title)
                        .foregroundStyle(services.sensors.isLogging ? .red : .green)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(services.sensors.isLogging ? "Live Logging" : "Ready to Log")
                            .font(.headline)
                        Text(loggingSubtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Button {
                        if services.sensors.isLogging {
                            services.sensors.stopLogging()
                            services.log("Sensor live logging stopped with \(services.sensors.loggedSamples.count) samples")
                        } else {
                            services.sensors.startLogging()
                            services.log("Sensor live logging started")
                        }
                    } label: {
                        Label(services.sensors.isLogging ? "Stop" : "Start Logging", systemImage: services.sensors.isLogging ? "stop.fill" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack(spacing: 10) {
                    SensorSessionStat(title: "Samples", value: "\(services.sensors.loggedSamples.count)")
                    SensorSessionStat(title: "Streams", value: "\(selectedGraphMetrics.count)")
                    SensorSessionStat(title: "Updated", value: services.sensors.lastUpdated.formatted(date: .omitted, time: .standard))
                }

                if !services.sensors.loggedSamples.isEmpty {
                    HStack {
                        Button {
                            services.log(services.sensors.exportLoggedCSV())
                        } label: {
                            Label("Log Session CSV", systemImage: "tablecells")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            services.sensors.clearLoggedSamples()
                            services.log("Sensor live logging cleared")
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var sensorSelectionPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Detailed Graphs")
                        .font(.headline)
                    Spacer()
                    Button("All") {
                        selectedSensors = Set(graphableMetrics.map(\.title))
                    }
                    .buttonStyle(.bordered)
                    Button("Motion") {
                        selectedSensors = ["Accelerometer", "Gyroscope", "Magnetometer", "Device Motion"]
                    }
                    .buttonStyle(.bordered)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 8)], spacing: 8) {
                    ForEach(graphableMetrics) { metric in
                        Toggle(isOn: Binding(
                            get: { selectedSensors.contains(metric.title) },
                            set: { isSelected in
                                if isSelected {
                                    selectedSensors.insert(metric.title)
                                } else {
                                    selectedSensors.remove(metric.title)
                                }
                            }
                        )) {
                            Label(metric.title, systemImage: metric.symbol)
                                .font(.caption)
                        }
                        .toggleStyle(.button)
                    }
                }
            }
        }
    }

    private var exportPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Export")
                    .font(.headline)
                HStack {
                    Button {
                        services.log(services.sensors.exportCSV())
                    } label: {
                        Label("Snapshot CSV", systemImage: "doc.plaintext")
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        services.log(services.sensors.exportJSON())
                    } label: {
                        Label("Snapshot JSON", systemImage: "curlybraces")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var loggingSubtitle: String {
        if let startedAt = services.sensors.loggingStartedAt, services.sensors.isLogging {
            return "Started \(startedAt.formatted(date: .omitted, time: .shortened))"
        }
        if services.sensors.loggedSamples.isEmpty {
            return "Press Start Logging to record live motion, pressure, location, heading, display, and device readings."
        }
        return "\(services.sensors.loggedSamples.count) samples captured"
    }
}

private struct SensorSessionStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DetailedSensorGraph: View {
    let metric: SensorMetric
    let samples: [SensorLogSample]
    let isLogging: Bool

    private var values: [Double] {
        let sessionValues = samples.suffix(240).map(\.value)
        return sessionValues.isEmpty ? metric.trend : sessionValues
    }

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(metric.title, systemImage: metric.symbol)
                        .font(.headline)
                        .foregroundStyle(metric.tint)
                    Spacer()
                    Text(samples.isEmpty ? "Live preview" : "\(samples.count) samples")
                        .font(.caption)
                        .foregroundStyle(isLogging ? .green : AppTheme.secondaryText)
                }
                Text(metric.detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
                SensorLineGraph(values: values, tint: metric.tint)
                    .frame(height: 154)
                HStack {
                    Text("Min \(formatted(values.min()))")
                    Spacer()
                    Text("Max \(formatted(values.max()))")
                    Spacer()
                    Text("Latest \(formatted(values.last))")
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.3f", value)
    }
}

private struct SensorLineGraph: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.28))
                GraphGrid()
                    .stroke(AppTheme.hairline.opacity(0.6), lineWidth: 1)
                graphPath(size: proxy.size)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                if values.count < 2 {
                    Text("Waiting for movement")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func graphPath(size: CGSize) -> Path {
        let safeValues = Array(values.suffix(240))
        guard safeValues.count > 1 else { return Path() }
        let minimum = safeValues.min() ?? 0
        let maximum = safeValues.max() ?? 1
        let span = max(maximum - minimum, 0.0001)
        let stepX = size.width / CGFloat(max(safeValues.count - 1, 1))

        return Path { path in
            for index in safeValues.indices {
                let x = CGFloat(index) * stepX
                let normalized = (safeValues[index] - minimum) / span
                let y = size.height - CGFloat(normalized) * size.height
                if index == safeValues.startIndex {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

private struct GraphGrid: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            for index in 1..<4 {
                let y = rect.height * CGFloat(index) / 4
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            for index in 1..<4 {
                let x = rect.width * CGFloat(index) / 4
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
        }
    }
}
