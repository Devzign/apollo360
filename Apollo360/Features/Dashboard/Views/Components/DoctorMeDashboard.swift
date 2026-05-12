//
//  DoctorMeDashboard.swift
//  Apollo360
//

import SwiftUI

struct DoctorMeDashboard: View {
    let doctorMetrics: [DashboardMetricCardModel]
    let myMetrics: [DashboardMetricCardModel]
    let isLoading: Bool
    let errorMessage: String?
    let onSelectMetrics: () -> Void

    private var syncingCount: Int {
        (doctorMetrics + myMetrics).filter { $0.syncStatus.lowercased() == "critical" }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                syncBanner

                if isLoading && doctorMetrics.isEmpty && myMetrics.isEmpty {
                    ProgressView("Loading dashboard metrics...")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                }

                if let errorMessage, !errorMessage.isEmpty, doctorMetrics.isEmpty && myMetrics.isEmpty {
                    Text(errorMessage)
                        .font(AppFont.body(size: 13, weight: .medium))
                        .foregroundColor(AppColor.red)
                }

                metricSection(title: "Doctor Prescribed", metrics: doctorMetrics)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        sectionTitle("Added By Me", count: myMetrics.count)
                        Spacer()
                        Button("Select Metrics", action: onSelectMetrics)
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.black.opacity(0.8))
                    }
                    metricList(metrics: myMetrics)
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color(red: 250 / 255, green: 251 / 255, blue: 248 / 255))
    }

    private var syncBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.horizontal.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColor.grey)

            Text(syncingCount == 1 ? "1 metric need syncing" : "\(syncingCount) metrics need syncing")
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundColor(AppColor.grey)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
        )
    }

    @ViewBuilder
    private func metricSection(title: String, metrics: [DashboardMetricCardModel]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title, count: metrics.count)
            metricList(metrics: metrics)
        }
    }

    @ViewBuilder
    private func metricList(metrics: [DashboardMetricCardModel]) -> some View {
        if metrics.isEmpty {
            Text("No metrics available.")
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundColor(AppColor.grey)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(metrics) { metric in
                    DoctorMeMetricCard(metric: metric)
                }
            }
        }
    }

    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "stethoscope")
                .font(.system(size: 11))
                .foregroundColor(AppColor.blue)
            Text("\(title) (\(count))")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.82))
        }
    }
}

private struct DoctorMeMetricCard: View {
    let metric: DashboardMetricCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(metric.title)
                    .font(AppFont.body(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.9))
                    .lineLimit(2)
                Spacer()
                Text(metric.statusBadgeText)
                    .font(AppFont.body(size: 10, weight: .semibold))
                    .foregroundColor(metric.statusBadgeTint)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Capsule().fill(metric.statusBadgeBackground))
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(metric.latestValueText)
                    .font(AppFont.display(size: 34, weight: .bold))
                    .foregroundColor(AppColor.black)
                Text(metric.unitText.isEmpty ? "-" : metric.unitText)
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundColor(AppColor.color414141.opacity(0.82))
            }

            HStack {
                Text("Source: \(metric.sourceText)")
                    .font(AppFont.body(size: 10, weight: .medium))
                    .foregroundColor(AppColor.grey)
                Spacer()
                Text(metric.lastSyncText)
                    .font(AppFont.body(size: 10, weight: .medium))
                    .foregroundColor(AppColor.grey)
            }

            Text(metric.trendText)
                .font(AppFont.body(size: 11, weight: .semibold))
                .foregroundColor(metric.trendTint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
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

