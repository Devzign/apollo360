import SwiftUI

struct ScoreBreakdownView: View {
    let score: Int
    let mode: WellnessMode
    let metrics: [WellnessMetric]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Score Breakdown")
                    .font(AppFont.display(size: 24, weight: .bold))
                    .foregroundStyle(AppColor.black)

                Text("Mode: \(mode.rawValue.capitalized)")
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.grey)

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 12)

                    VStack(spacing: 18) {
                        RadarChart(values: radarValues, labels: radarLabels, axisColors: axisColors, series: metricSeries + comparisonSeries)
                            .frame(height: 220)

                        VStack(spacing: 6) {
                            Text("\(score)")
                                .font(AppFont.display(size: 48, weight: .bold))
                                .foregroundStyle(AppColor.black)
                            Text("You are a very healthy individual.")
                                .font(AppFont.body(size: 14, weight: .medium))
                                .foregroundStyle(AppColor.grey)
                        }

                        HStack(spacing: 16) {
                            ForEach(displayMetrics) { metric in
                                LegendDot(color: metric.color, label: metric.title)
                            }
                        }
                    }
                    .padding(28)
                }

                VStack(spacing: 12) {
            ForEach(displayMetrics) { metric in
                HStack {
                    Text(metric.title)
                        .font(AppFont.body(size: 16, weight: .semibold))
                                .foregroundStyle(AppColor.black)
                            Spacer()
                            Text("\(Int(metric.value.rounded()))")
                                .font(AppFont.body(size: 16, weight: .bold))
                                .foregroundStyle(metric.color)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        )
                    }
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.92, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private var displayMetrics: [DisplayMetric] {
        let ordered = ["Activity", "Sleep", "Heart", "Nutrition"]
        let colors: [String: Color] = [
            "activity": Color(red: 0.27, green: 0.66, blue: 0.33),
            "sleep": Color(red: 0.56, green: 0.23, blue: 0.91),
            "heart": Color(red: 0.87, green: 0.24, blue: 0.3),
            "nutrition": Color(red: 0.99, green: 0.47, blue: 0.19)
        ]
        let map = Dictionary(grouping: metrics, by: { $0.title.lowercased() })
        return ordered.compactMap { name in
            guard let metric = map[name.lowercased()]?.first else { return nil }
            return DisplayMetric(
                title: metric.title,
                value: Double(metric.current),
                color: colors[name.lowercased()] ?? AppColor.green
            )
        }
    }

    private var radarValues: [Double] {
        displayMetrics.map { min(max($0.value / 100.0, 0), 1) }
    }

    private var radarLabels: [String] {
        displayMetrics.map { $0.title }
    }

    private var axisColors: [Color] {
        displayMetrics.map { $0.color.opacity(0.6) }
    }

    private var metricSeries: [MetricSeries] {
        displayMetrics.enumerated().map { index, metric in
            var values = Array(repeating: 0.0, count: displayMetrics.count)
            values[index] = min(max(metric.value / 100.0, 0), 1)
            return MetricSeries(values: values, color: metric.color)
        }
    }

    private var comparisonSeries: [MetricSeries] {
        let baseValues = radarValues
        return [
            MetricSeries(
                values: baseValues.map { min($0 + 0.15, 1) },
                color: Color.black.opacity(0.35)
            ),
            MetricSeries(
                values: baseValues.map { max($0 - 0.15, 0) },
                color: AppColor.grey.opacity(0.4)
            )
        ]
    }
}

private struct DisplayMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let color: Color
}

private struct MetricSeries: Identifiable {
    let id = UUID()
    let values: [Double]
    let color: Color
}

private struct RadarChart: View {
    let values: [Double]
    let labels: [String]
    let axisColors: [Color]
    let series: [MetricSeries]

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                ForEach(1...5, id: \.self) { step in
                    Polygon(sides: values.count, scale: CGFloat(step) / 5)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }

                ForEach(series) { metricSeries in
                    Polygon(points: radarPoints(radius: radius, center: center, values: metricSeries.values))
                        .fill(metricSeries.color.opacity(0.3))
                        .position(center)
                    Polygon(points: radarPoints(radius: radius, center: center, values: metricSeries.values))
                        .stroke(metricSeries.color.opacity(0.6), lineWidth: 2)
                        .position(center)
                    if let firstIndex = metricSeries.values.firstIndex(where: { $0 > 0 }) {
                        let point = radarPoints(radius: radius, center: center, values: metricSeries.values)[firstIndex]
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: point)
                        }
                        .stroke(metricSeries.color.opacity(0.8), lineWidth: 1.5)
                        .position(center)
                    }
                }

                ForEach(Array(zip(labels.indices, labels)), id: \.0) { index, label in
                    Text(label)
                        .font(AppFont.body(size: 11, weight: .semibold))
                        .foregroundStyle(axisColors[safe: index] ?? AppColor.grey)
                        .position(labelPosition(index: index, radius: radius + 14, center: center))
                }
            }
        }
    }

    private func radarPoints(radius: CGFloat, center: CGPoint, values: [Double]? = nil) -> [CGPoint] {
        let source = values ?? self.values
        let count = source.count
        var points: [CGPoint] = []

        for index in 0..<count {
            let angle = (Double(index) / Double(count)) * .pi * 2 - .pi / 2
            let length = max(0, min(1, source[index])) * Double(radius)
            points.append(
                CGPoint(
                    x: center.x + CGFloat(cos(angle)) * CGFloat(length),
                    y: center.y + CGFloat(sin(angle)) * CGFloat(length)
                )
            )
        }

        return points
    }

    private func labelPosition(index: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let count = labels.count
        let angle = (Double(index) / Double(count)) * .pi * 2 - .pi / 2
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius,
            y: center.y + CGFloat(sin(angle)) * radius
        )
    }
}

private struct Polygon: Shape {
    let sides: Int
    let scale: CGFloat
    let explicitPoints: [CGPoint]?

    init(sides: Int, scale: CGFloat = 1) {
        self.sides = max(3, sides)
        self.scale = scale
        self.explicitPoints = nil
    }

    init(points: [CGPoint]) {
        self.sides = max(3, points.count)
        self.scale = 1
        self.explicitPoints = points
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * scale

        if let points = explicitPoints, !points.isEmpty {
            path.move(to: points[0])
            for pt in points.dropFirst() {
                path.addLine(to: pt)
            }
            path.closeSubpath()
        } else {
            for index in 0..<sides {
                let angle = (Double(index) / Double(sides)) * Double.pi * 2 - Double.pi / 2
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }

        return path
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundStyle(AppColor.black)
        }
    }
}

#Preview {
    ScoreBreakdownView(
        score: 88,
        mode: .absolute,
        metrics: [
            WellnessMetric(title: "Calorie", current: 78, previous: 0, tint: AppColor.green),
            WellnessMetric(title: "BMI", current: 70, previous: 0, tint: AppColor.blue),
            WellnessMetric(title: "BPM", current: 68, previous: 0, tint: AppColor.red),
            WellnessMetric(title: "Hydration", current: 82, previous: 0, tint: AppColor.yellow),
            WellnessMetric(title: "Sleep", current: 73, previous: 0, tint: AppColor.colorECF0F3),
        ]
    )
}
