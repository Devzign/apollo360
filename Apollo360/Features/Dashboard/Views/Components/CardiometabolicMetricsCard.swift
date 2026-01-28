//
//  CardiometabolicMetricsCard.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

struct CardiometabolicMetricsCard: View {
    let metrics: [CardioMetric]

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cardiometabolic Metrics")
                        .font(AppFont.display(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.black)
                    Text("Key health trends over the past week")
                        .font(AppFont.body(size: 13))
                        .foregroundStyle(AppColor.grey)
                }

                VStack(spacing: 16) {
                    ForEach(metrics) { metric in
                        CardioMetricRowView(metric: metric)
                    }
                }
            }
        }
    }
}

private struct CardioMetricRowView: View {
    let metric: CardioMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(metric.title)
                    .font(AppFont.body(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.black)

                Spacer()

                Text("\(metric.value) \(metric.unit)")
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundStyle(AppColor.black)
            }

            MetricSparklineView(values: metric.sparkline, color: metric.tint)
                .frame(height: 36)

            Text(metric.trend)
                .font(AppFont.body(size: 12))
                .foregroundStyle(metric.tint)
        }
        .padding(12)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MetricSparklineView: View {
    let values: [Double]
    let color: Color

    @State private var drawProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let points = normalized(values: values)
            let width = geometry.size.width
            let height = geometry.size.height
            let step = points.count > 1 ? width / CGFloat(points.count - 1) : 0

            let fullPath = SparklineShape(values: points, step: step, height: height)

            ZStack {
                Path { path in
                    guard points.count > 1 else { return }
                    for index in points.indices {
                        let x = CGFloat(index) * step
                        let y = height - (CGFloat(points[index]) * height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.black.opacity(0.08), lineWidth: 1)

                fullPath
                    .trim(from: 0, to: drawProgress)
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.6, lineCap: .round)
                    )
                    .shadow(color: color.opacity(0.25), radius: 4, x: 0, y: 2)
            }
        }
        .onAppear(perform: restartAnimation)
        .onChange(of: values) { _ in
            restartAnimation()
        }
    }

    private func restartAnimation() {
        drawProgress = 0
        withAnimation(.easeOut(duration: 1.2)) {
            drawProgress = 1
        }
    }

    private func normalized(values: [Double]) -> [Double] {
        guard let minValue = values.min(), let maxValue = values.max(), maxValue != minValue else {
            return values.map { _ in 0.5 }
        }
        return values.map { ($0 - minValue) / (maxValue - minValue) }
    }
}

private struct SparklineShape: Shape {
    let values: [Double]
    let step: CGFloat
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }

        for index in values.indices {
            let x = CGFloat(index) * step
            let y = height - (CGFloat(values[index]) * height)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        AnimatablePair(step, height)
    }
}

#Preview {
    CardiometabolicMetricsCard(
        metrics: [
            CardioMetric(
                title: "Blood Pressure",
                value: "121/77",
                unit: "mmHg",
                trend: "+1% from last week",
                tint: AppColor.red,
                sparkline: [0.62, 0.64, 0.61, 0.66, 0.63, 0.65, 0.64]
            ),
            CardioMetric(
                title: "Resting Heart Rate",
                value: "65",
                unit: "bpm",
                trend: "-3 bpm from last week",
                tint: AppColor.green,
                sparkline: [0.56, 0.52, 0.54, 0.51, 0.49, 0.5, 0.48]
            ),
            CardioMetric(
                title: "Glucose",
                value: "96",
                unit: "mg/dL",
                trend: "Stable this week",
                tint: AppColor.yellow,
                sparkline: [0.48, 0.52, 0.5, 0.47, 0.49, 0.48, 0.46]
            )
        ]
    )
    .padding()
}
