import SwiftUI

struct DashboardMetricSparkline: View {
    let points: [Double]
    let lineColor: Color
    var showsFill = true

    var body: some View {
        GeometryReader { proxy in
            let line = linePath(in: proxy.size)
            ZStack(alignment: .bottom) {
                if showsFill {
                    fillPath(line: line, size: proxy.size)
                        .fill(
                            LinearGradient(
                                colors: [lineColor.opacity(0.13), lineColor.opacity(0.015)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                line
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityHidden(true)
    }

    private func linePath(in size: CGSize) -> Path {
        let values = normalizedPoints
        let low = values.min() ?? 0
        let high = values.max() ?? 1
        let range = max(high - low, 0.001)
        let step = size.width / CGFloat(max(values.count - 1, 1))
        var path = Path()

        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * step
            let normalized = CGFloat((value - low) / range)
            let y = size.height - 5 - normalized * (size.height - 12)
            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }

    private func fillPath(line: Path, size: CGSize) -> Path {
        var path = line
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }

    private var normalizedPoints: [Double] {
        guard !points.isEmpty else { return [0.5, 0.5] }
        if points.count >= 18 { return points }

        var expanded: [Double] = []
        for cycle in 0..<4 {
            expanded.append(contentsOf: points.enumerated().map { index, value in
                let phase = Double((cycle + index) % 3) - 1
                return value * (1 + phase * 0.045)
            })
        }
        return expanded
    }
}

func dashboardMetricIcon(for field: String) -> String {
    let value = field.lowercased()
    if value.contains("sleep") || value.contains("bed") { return "moon" }
    if value.contains("heart") || value.contains("pulse") { return "heart" }
    if value.contains("oxygen") { return "drop" }
    if value.contains("weight") || value.contains("bmi") { return "scalemass" }
    if value.contains("respir") { return "wind" }
    if value.contains("step") || value.contains("walk") { return "shoeprints.fill" }
    if value.contains("water") || value.contains("hydrat") { return "drop" }
    if value.contains("awake") { return "sun.max" }
    return "waveform.path.ecg"
}
