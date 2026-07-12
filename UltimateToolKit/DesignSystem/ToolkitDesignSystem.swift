import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.018, green: 0.022, blue: 0.03, alpha: 1)
            : UIColor(red: 0.965, green: 0.975, blue: 0.99, alpha: 1)
    })
    static let backgroundAccent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.045, green: 0.06, blue: 0.09, alpha: 1)
            : UIColor(red: 0.90, green: 0.94, blue: 1.0, alpha: 1)
    })
    static let panel = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.white.withAlphaComponent(0.72)
    })
    static let elevatedPanel = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.white.withAlphaComponent(0.94)
    })
    static let hairline = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.black.withAlphaComponent(0.08)
    })
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color(UIColor.tertiaryLabel)
    static let terminalGreen = Color(red: 0.25, green: 0.95, blue: 0.35)
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.background, AppTheme.backgroundAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TechCircuitPattern()
                .stroke(AppTheme.hairline.opacity(0.55), lineWidth: 0.7)
                .ignoresSafeArea()

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
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

struct TechCircuitPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 42
        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }

        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }

        for index in 0..<5 {
            let offset = CGFloat(index) * 88
            path.move(to: CGPoint(x: rect.minX + offset, y: rect.minY + 120 + offset * 0.25))
            path.addLine(to: CGPoint(x: rect.minX + offset + 90, y: rect.minY + 120 + offset * 0.25))
            path.addLine(to: CGPoint(x: rect.minX + offset + 118, y: rect.minY + 148 + offset * 0.25))
        }
        return path
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
                let safeValues = Array(values.filter { $0.isFinite }.suffix(80))
                guard safeValues.count > 1 else { return }
                let bounds = stableBounds(for: safeValues)
                let span = max(bounds.upper - bounds.lower, 0.001)
                let plotHeight = max(1, proxy.size.height - 4)
                for index in safeValues.indices {
                    let x = proxy.size.width * CGFloat(index) / CGFloat(max(safeValues.count - 1, 1))
                    let normalized = min(1, max(0, (safeValues[index] - bounds.lower) / span))
                    let y = 2 + plotHeight * (1 - CGFloat(normalized))
                    if index == safeValues.startIndex {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }

    private func stableBounds(for values: [Double]) -> (lower: Double, upper: Double) {
        let sorted = values.sorted()
        guard let first = sorted.first, let last = sorted.last else { return (0, 1) }
        guard sorted.count > 8 else { return (first, last) }
        let lowIndex = max(0, Int(Double(sorted.count - 1) * 0.05))
        let highIndex = min(sorted.count - 1, Int(Double(sorted.count - 1) * 0.95))
        return (sorted[lowIndex], sorted[highIndex])
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
