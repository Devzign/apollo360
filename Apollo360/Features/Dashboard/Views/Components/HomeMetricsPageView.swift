//
//  HomeMetricsPageView.swift
//  Apollo360
//

import SwiftUI

struct HomeMetricsPageView: View {
    let doctorMetrics: [DashboardMetricCardModel]
    let myMetrics: [DashboardMetricCardModel]
    let isLoading: Bool
    let errorMessage: String?
    let onSelectMetrics: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                syncBanner

                if isLoading && doctorMetrics.isEmpty && myMetrics.isEmpty {
                    ProgressView("Loading dashboard metrics...")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                }

                if let errorMessage, !errorMessage.isEmpty, doctorMetrics.isEmpty && myMetrics.isEmpty {
                    Text(errorMessage)
                        .font(AppFont.body(size: 13, weight: .medium))
                        .foregroundColor(AppColor.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                metricSection(title: "Doctor Prescribed", count: doctorMetrics.count, metrics: doctorMetrics)

                VStack(spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        sectionHeading(title: "Added by me", count: myMetrics.count)
                        Spacer()
                        Button("Select Metrics", action: onSelectMetrics)
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.black.opacity(0.78))
                    }

                    metricsGrid(metrics: myMetrics)
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color(red: 250 / 255, green: 251 / 255, blue: 248 / 255))
    }

    private var syncBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.horizontal.circle")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.grey.opacity(0.9))
            Text("3 metrics need syncing")
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundColor(AppColor.grey)
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 10, y: 3)
        )
    }

    @ViewBuilder
    private func metricSection(title: String, count: Int, metrics: [DashboardMetricCardModel]) -> some View {
        VStack(spacing: 14) {
            sectionHeading(title: title, count: count)
            metricsGrid(metrics: metrics)
        }
    }

    private func sectionHeading(title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 11))
                .foregroundColor(AppColor.blue)

            Text("\(title) (\(count))")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func metricsGrid(metrics: [DashboardMetricCardModel]) -> some View {
        if metrics.isEmpty {
            Text("No metrics available.")
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundColor(AppColor.grey)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(metrics) { metric in
                    HomeMetricCardView(metric: metric)
                }
            }
        }
    }
}

private struct HomeMetricCardView: View {
    let metric: DashboardMetricCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.title)
                        .font(AppFont.body(size: 11, weight: .semibold))
                        .foregroundColor(metric.isHero ? .white.opacity(0.96) : AppColor.color414141.opacity(0.92))
                        .lineLimit(2)

                    Text(metric.lastSyncText)
                        .font(AppFont.body(size: 9, weight: .medium))
                        .foregroundColor(metric.isHero ? .white.opacity(0.72) : AppColor.grey.opacity(0.95))
                }

                Spacer(minLength: 8)

                statusBadge
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.latestValueText)
                    .font(AppFont.display(size: metric.isHero ? 31 : 28, weight: .bold))
                    .foregroundColor(metric.isHero ? .white : AppColor.black)

                if !metric.unitText.isEmpty {
                    Text(metric.unitText)
                        .font(AppFont.body(size: 11, weight: .medium))
                        .foregroundColor(metric.isHero ? .white.opacity(0.88) : AppColor.color414141.opacity(0.82))
                }
            }

            Spacer(minLength: 0)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Source: \(metric.sourceText)")
                        .font(AppFont.body(size: 9, weight: .medium))
                        .foregroundColor(metric.isHero ? .white.opacity(0.72) : AppColor.grey.opacity(0.95))

                    Text(metric.trendText)
                        .font(AppFont.body(size: 10, weight: .semibold))
                        .foregroundColor(metric.isHero ? .white.opacity(0.88) : metric.trendTint)
                }
                Spacer()
            }

            MetricMiniSparkline(points: metric.sparkline, isHero: metric.isHero)
                .frame(height: metric.isHero ? 64 : 54)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: metric.isHero ? 184 : 160, alignment: .topLeading)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(metric.isHero ? Color.clear : borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(metric.isHero ? 0.08 : 0.04), radius: 14, y: 5)
    }

    private var statusBadge: some View {
        Text(metric.statusBadgeText)
            .font(AppFont.body(size: 10, weight: .semibold))
            .foregroundColor(metric.isHero ? metric.statusBadgeTint : metric.statusBadgeTint)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(
                Capsule()
                    .fill(metric.isHero ? Color.white.opacity(0.2) : metric.statusBadgeBackground)
            )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                metric.isHero
                ? LinearGradient(
                    colors: [
                        Color(red: 66 / 255, green: 132 / 255, blue: 241 / 255),
                        Color(red: 48 / 255, green: 114 / 255, blue: 229 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [Color.white, Color(red: 251 / 255, green: 252 / 255, blue: 249 / 255)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var borderColor: Color {
        switch metric.syncStatus.lowercased() {
        case "critical":
            return Color(red: 247 / 255, green: 205 / 255, blue: 139 / 255)
        case "warning":
            return Color(red: 245 / 255, green: 220 / 255, blue: 153 / 255)
        default:
            return Color(red: 232 / 255, green: 238 / 255, blue: 229 / 255)
        }
    }
}

private struct MetricMiniSparkline: View {
    let points: [Double]
    let isHero: Bool

    var body: some View {
        GeometryReader { proxy in
            let path = sparklinePath(in: proxy.size)
            ZStack(alignment: .bottom) {
                if isHero {
                    path
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    path
                        .fill(
                            LinearGradient(
                                colors: [AppColor.green.opacity(0.18), AppColor.green.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                strokePath(in: proxy.size)
                    .stroke(isHero ? Color.white.opacity(0.72) : AppColor.green.opacity(0.34), lineWidth: 2)
            }
        }
    }

    private func sparklinePath(in size: CGSize) -> Path {
        var path = strokePath(in: size)
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }

    private func strokePath(in size: CGSize) -> Path {
        let values = points.isEmpty ? [0.3, 0.5, 0.4, 0.6] : points
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let scale = max(maxValue - minValue, 0.01)
        let step = size.width / CGFloat(max(values.count - 1, 1))

        var path = Path()
        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * step
            let normalized = (value - minValue) / scale
            let y = size.height - (size.height * CGFloat(normalized) * 0.88) - 2
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
