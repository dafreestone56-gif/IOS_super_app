import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.02, green: 0.025, blue: 0.03)
    static let panel = Color.white.opacity(0.075)
    static let elevatedPanel = Color.white.opacity(0.11)
    static let hairline = Color.white.opacity(0.08)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.62)
    static let tertiaryText = Color.white.opacity(0.38)
    static let terminalGreen = Color(red: 0.25, green: 0.95, blue: 0.35)
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            content
        }
    }
}

extension View {
    func toolkitScreen() -> some View {
        modifier(ScreenBackground())
    }
}

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )
    }
}

struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.top, 8)
    }
}

struct ModuleCard: View {
    let module: ToolkitModule

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: module.symbol)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(module.tint.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(module.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(module.statusText)
                    .font(.caption2)
                    .foregroundStyle(module.tint.opacity(0.9))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(minHeight: 72)
        .background(module.tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(module.tint.opacity(0.12), lineWidth: 1)
        )
    }
}

struct ToolRow: View {
    let module: ToolkitModule
    var trailing: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: module.symbol)
                .font(.headline)
                .foregroundStyle(module.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(module.title)
                    .font(.body)
                    .foregroundStyle(AppTheme.primaryText)
                Text(module.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.vertical, 10)
    }
}

struct MetricCard: View {
    let metric: SensorMetric

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: metric.symbol)
                .font(.title3)
                .foregroundStyle(metric.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(metric.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(metric.detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(metric.value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(metric.tint)
                Sparkline(values: metric.trend, tint: metric.tint)
                    .frame(width: 76, height: 24)
            }
        }
        .padding(12)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct Sparkline: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                guard values.count > 1 else { return }
                let minValue = values.min() ?? 0
                let maxValue = values.max() ?? 1
                let span = max(maxValue - minValue, 0.001)
                for index in values.indices {
                    let x = proxy.size.width * CGFloat(index) / CGFloat(values.count - 1)
                    let normalized = (values[index] - minValue) / span
                    let y = proxy.size.height * (1 - CGFloat(normalized))
                    if index == values.startIndex {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

struct TerminalSurface: View {
    let lines: [ConsoleLine]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                if lines.isEmpty {
                    Text("No terminal data yet. Connect to a writable or notifying characteristic.")
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(lines) { line in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(line.direction.rawValue)
                                .foregroundStyle(line.direction == .outbound ? AppTheme.terminalGreen : AppTheme.secondaryText)
                            Text(line.text)
                                .foregroundStyle(line.direction == .outbound ? AppTheme.terminalGreen : AppTheme.primaryText)
                        }
                    }
                }
            }
            .font(.system(.footnote, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .frame(minHeight: 260)
        .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }
}
