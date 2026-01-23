//
//  MetricsView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct MetricsView: View {
    @State private var selectedRange = "1D"
    @State private var isFeeling = false
    let horizontalPadding: CGFloat

    private let cards: [MetricCard] = [
        MetricCard(
            title: "Active Duration",
            lastValue: "28.00 minutes",
            averageValue: "28.00",
            dateRange: "Dec 27 2024 → Jan 03 2025",
            points: [18, 26, 34, 20, 46, 58, 45, 64, 52]
        ),
        MetricCard(
            title: "Active Energy Burned",
            lastValue: "35.04 kcal",
            averageValue: "69.08",
            dateRange: "Jul 08 2025 → Jul 15 2025",
            points: [14, 28, 38, 24, 55, 62, 48, 54, 60]
        ),
        MetricCard(
            title: "Avg Speed",
            lastValue: "4.47 mph",
            averageValue: "4.47",
            dateRange: "Jan 03 2025 → Jan 03 2025",
            points: [10, 22, 40, 32, 65, 70, 60, 48, 55]
        )
    ]

    private let ranges = ["1D", "1W", "1M", "3M", "1Y", "All"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                InfoCard()

                HStack {
                    Text("Added by Care Team")
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.black.opacity(0.7))

                    Spacer()

                    Toggle("I'm Feeling", isOn: $isFeeling)
                        .toggleStyle(SwitchToggleStyle(tint: AppColor.green))
                        .labelsHidden()
                }
                .padding(.horizontal, 12)

                VStack(spacing: 20) {
                    ForEach(cards) { card in
                        MetricCardView(
                            metric: card,
                            selectedRange: selectedRange,
                            ranges: ranges,
                            onRangeChange: { range in
                                withAnimation {
                                    selectedRange = range
                                }
                            }
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(AppColor.secondary.ignoresSafeArea())
    }

    @ViewBuilder
    private func InfoCard() -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What is this?")
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.black)

                Text("Within this section, you can explore all of the health data that's relevant to your health journey. These analytics are monitored real time, and with your doctor's help can provide you with more ways to reach your health goals.")
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(AppColor.black.opacity(0.65))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColor.grey.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColor.green.opacity(0.14))
        )
    }
}

private struct MetricCard: Identifiable {
    let id = UUID()
    let title: String
    let lastValue: String
    let averageValue: String
    let dateRange: String
    let points: [Double]
}

private struct MetricCardView: View {
    let metric: MetricCard
    let selectedRange: String
    let ranges: [String]
    let onRangeChange: (String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            header
            ChartView(points: metric.points, rangeText: metric.dateRange)
            RangeSelector(ranges: ranges, selectedRange: selectedRange, onSelect: onRangeChange)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(metric.title)
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.black)

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 6) {
                        Text("Compare")
                            .font(AppFont.body(size: 14))
                            .foregroundStyle(AppColor.green)
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColor.green)
                    }
                    .padding(8)
                    .background(Capsule().fill(AppColor.green.opacity(0.16)))
                }
                .buttonStyle(.plain)
            }

            Text("Last: \(metric.lastValue)  Average: \(metric.averageValue)")
                .font(AppFont.body(size: 14))
                .foregroundStyle(AppColor.black.opacity(0.7))
        }
    }
}

private struct ChartView: View {
    let points: [Double]
    let rangeText: String

    var body: some View {
        GeometryReader { proxy in
            let fill = LinearGradient(
                colors: [AppColor.green.opacity(0.3), AppColor.green.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )

            ZStack(alignment: .bottomLeading) {
                SparklineShape(points: points, closes: true)
                    .fill(fill)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                SparklineShape(points: points)
                    .stroke(AppColor.green, lineWidth: 2.5)
            }
            .overlay(
                Text(rangeText)
                    .font(AppFont.body(size: 12))
                    .foregroundStyle(AppColor.grey)
                    .padding(.bottom, 8),
                alignment: .bottomLeading
            )
        }
        .frame(height: 180)
    }
}

private struct SparklineShape: Shape {
    let points: [Double]
    var closes: Bool = false

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }
        let minValue = points.min() ?? 0
        let maxValue = points.max() ?? 1
        let verticalScale = maxValue - minValue == 0 ? 1 : maxValue - minValue

        let step = rect.width / CGFloat(points.count - 1)

        return Path { path in
            for index in points.indices {
                let x = CGFloat(index) * step
                let normalized = (points[index] - minValue) / verticalScale
                let y = rect.height * (1 - normalized)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            if closes {
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))
                path.addLine(to: CGPoint(x: 0, y: rect.height))
                path.closeSubpath()
            }
        }
    }
}

private struct RangeSelector: View {
    let ranges: [String]
    let selectedRange: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ranges, id: \.self) { range in
                Button(action: { onSelect(range) }) {
                    Text(range)
                        .font(AppFont.body(size: 12, weight: .semibold))
                        .foregroundStyle(range == selectedRange ? AppColor.green : AppColor.grey)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(range == selectedRange ? AppColor.green.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    MetricsView(horizontalPadding: 20)
}
