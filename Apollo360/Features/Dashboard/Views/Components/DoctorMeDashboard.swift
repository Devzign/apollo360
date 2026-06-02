import SwiftUI

struct DoctorMeDashboard: View {
    let doctorMetrics: [DashboardMetricCardModel]
    let myMetrics: [DashboardMetricCardModel]
    let isLoading: Bool
    let errorMessage: String?
    let session: SessionManager
    let onSelectMetrics: () -> Void

    @State private var selectedMetric: DashboardMetricCardModel?
    @State private var instructionSource: SyncInstructionSource?

    private var syncingCount: Int {
        (doctorMetrics + myMetrics).filter { isOlderThan48Hours($0.lastSyncDateRaw) }.count
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
        .sheet(item: $selectedMetric) { metric in
            DashboardMetricDetailSheet(metric: metric, session: session)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $instructionSource) { source in
            SyncInstructionSheet(source: source.value)
                .presentationDetents([.fraction(0.42)])
                .presentationDragIndicator(.visible)
        }
    }

    private var syncBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.horizontal.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColor.grey)

            Text(syncingCount == 1 ? "1 metric needs syncing" : "\(syncingCount) metrics need syncing")
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundColor(AppColor.grey)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
    }

    @ViewBuilder
    private func metricSection(title: String, metrics: [DashboardMetricCardModel]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title, count: max(0, metrics.count - (title == "Doctor Prescribed" ? 2 : 0)))

            if title == "Doctor Prescribed" {
                if metrics.indices.contains(0) {
                    HeroMetricCard(metric: metrics[0], style: .primaryHero) {
                        selectedMetric = metrics[0]
                    } onInstructionTap: {
                        instructionSource = SyncInstructionSource(value: metrics[0].sourceText)
                    }
                }
                if metrics.indices.contains(1) {
                    HeroMetricCard(metric: metrics[1], style: .secondaryHero) {
                        selectedMetric = metrics[1]
                    } onInstructionTap: {
                        instructionSource = SyncInstructionSource(value: metrics[1].sourceText)
                    }
                }
                metricList(metrics: Array(metrics.dropFirst(2)))
            } else {
                metricList(metrics: metrics)
            }
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
                    DoctorMeMetricCard(metric: metric) {
                        selectedMetric = metric
                    } onInstructionTap: {
                        instructionSource = SyncInstructionSource(value: metric.sourceText)
                    }
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
