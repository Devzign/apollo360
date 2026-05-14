import SwiftUI
import Charts

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

private struct DoctorMeMetricCard: View {
    let metric: DashboardMetricCardModel
    let onTap: () -> Void
    let onInstructionTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(metric.title)
                        .font(AppFont.body(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.black.opacity(0.9))
                        .lineLimit(2)
                    Spacer()
                    statusBadge
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
                    Button(action: onInstructionTap) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(AppColor.grey.opacity(0.8))
                    }
                    .buttonStyle(.plain)
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
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(borderColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var statusBadge: some View {
        Text(metric.statusBadgeText)
            .font(AppFont.body(size: 10, weight: .semibold))
            .foregroundColor(metric.statusBadgeTint)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Capsule().fill(metric.statusBadgeBackground))
    }

    private var borderColor: Color {
        if isOlderThan48Hours(metric.lastSyncDateRaw) {
            return Color(red: 250 / 255, green: 198 / 255, blue: 66 / 255)
        }
        return Color(red: 232 / 255, green: 238 / 255, blue: 229 / 255)
    }
}

private struct HeroMetricCard: View {
    enum Style { case primaryHero, secondaryHero }

    let metric: DashboardMetricCardModel
    let style: Style
    let onTap: () -> Void
    let onInstructionTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(metric.title)
                        .font(AppFont.body(size: 17, weight: .semibold))
                        .foregroundColor(titleColor)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(metaColor)
                        Text(metric.lastSyncText)
                            .font(AppFont.body(size: 11, weight: .medium))
                            .foregroundColor(metaColor)

                        Button(action: onInstructionTap) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(metaColor)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 7) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(metric.latestValueText)
                            .font(AppFont.display(size: 36, weight: .bold))
                            .foregroundColor(valueColor)
                        Text(metric.unitText)
                            .font(AppFont.body(size: 12, weight: .medium))
                            .foregroundColor(metaColor)
                    }
                    Text(metric.statusBadgeText)
                        .font(AppFont.body(size: 11, weight: .semibold))
                        .foregroundColor(metric.statusBadgeTint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(metric.statusBadgeBackground))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(background)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var background: some ShapeStyle {
        if style == .primaryHero && !isOlderThan48Hours(metric.lastSyncDateRaw) {
            return AnyShapeStyle(LinearGradient(colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        return AnyShapeStyle(Color(red: 0.98, green: 0.96, blue: 0.89))
    }

    private var border: Color {
        isOlderThan48Hours(metric.lastSyncDateRaw) ? Color(red: 250 / 255, green: 198 / 255, blue: 66 / 255) : Color.clear
    }

    private var titleColor: Color {
        (style == .primaryHero && !isOlderThan48Hours(metric.lastSyncDateRaw)) ? .white : AppColor.black
    }

    private var valueColor: Color {
        (style == .primaryHero && !isOlderThan48Hours(metric.lastSyncDateRaw)) ? .white : AppColor.black
    }

    private var metaColor: Color {
        (style == .primaryHero && !isOlderThan48Hours(metric.lastSyncDateRaw)) ? .white.opacity(0.86) : AppColor.grey
    }
}

private struct DashboardMetricDetailSheet: View {
    let metric: DashboardMetricCardModel
    let session: SessionManager

    @State private var compactPoints: [Double] = []
    @State private var detailPoints: [Double] = []
    @State private var compactAverage = "--"
    @State private var detailAverage = "--"
    @State private var compactRange = "Last 30 days"
    @State private var detailRange = "Last 365 days"
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(metric.title)
                    .font(AppFont.display(size: 30, weight: .semibold))
                Text("\(metric.latestValueText) \(metric.unitText)")
                    .font(AppFont.body(size: 20, weight: .medium))
                    .foregroundColor(AppColor.color414141)

                Group {
                    Text("30-Day Trend")
                        .font(AppFont.body(size: 16, weight: .semibold))
                    trendChart(points: compactPoints)
                    Text("Avg: \(compactAverage) • \(compactRange)")
                        .font(AppFont.body(size: 12, weight: .medium))
                        .foregroundColor(AppColor.grey)
                }

                Divider()

                Group {
                    Text("Last 365 Days Trend")
                        .font(AppFont.body(size: 16, weight: .semibold))
                    trendChart(points: detailPoints)
                    Text("Avg: \(detailAverage) • \(detailRange)")
                        .font(AppFont.body(size: 12, weight: .medium))
                        .foregroundColor(AppColor.grey)
                }

                if isLoading {
                    ProgressView("Loading chart...")
                        .font(AppFont.body(size: 12, weight: .medium))
                }
            }
            .padding(18)
        }
        .task { await loadCharts() }
    }

    @ViewBuilder
    private func trendChart(points: [Double]) -> some View {
        if points.isEmpty {
            Text("No chart data")
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundColor(AppColor.grey)
                .frame(maxWidth: .infinity)
                .frame(height: 170)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        } else {
            Chart(Array(points.enumerated()), id: \.offset) { index, value in
                LineMark(x: .value("Index", index), y: .value("Value", value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(AppColor.green)
            }
            .frame(height: 170)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        }
    }

    private func loadCharts() async {
        guard let patientId = session.patientId,
              let token = session.accessToken else { return }
        isLoading = true
        let service = MetricsAPIService.shared

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await loadSeries(days: "30", patientId: patientId, token: token, service: service) { payload in
                    compactPoints = payload.points
                    compactAverage = payload.averageValueText
                    compactRange = payload.dateRangeText
                }
            }
            group.addTask {
                await loadSeries(days: "365", patientId: patientId, token: token, service: service) { payload in
                    detailPoints = payload.points
                    detailAverage = payload.averageValueText
                    detailRange = payload.dateRangeText
                }
            }
        }
        isLoading = false
    }

    private func loadSeries(days: String,
                            patientId: String,
                            token: String,
                            service: MetricsAPIService,
                            apply: @escaping @MainActor (UserMetricSeriesPayload) -> Void) async {
        await withCheckedContinuation { continuation in
            service.fetchUserMetricSeries(metricField: metric.metricField,
                                          patientId: patientId,
                                          selectedRange: days,
                                          source: .rpm,
                                          bearerToken: token) { result in
                if case .success(let payload) = result {
                    Task { @MainActor in apply(payload) }
                }
                continuation.resume()
            }
        }
    }
}

private struct SyncInstructionSource: Identifiable {
    let value: String
    var id: String { value }
}

private struct SyncInstructionSheet: View {
    let source: String

    private var normalized: String { source.lowercased() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sync Instructions")
                .font(AppFont.display(size: 28, weight: .semibold))
            Text("Source: \(source)")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.grey)

            Text(message)
                .font(AppFont.body(size: 14, weight: .regular))
                .foregroundColor(AppColor.color414141)

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    private var message: String {
        if normalized.contains("apple") {
            return "Open Device Sync and connect Apple Health. Then tap Sync to refresh this metric."
        }
        if normalized.contains("fitbit") {
            return "Open Device Sync and connect Fitbit account. After successful connection, run Sync again."
        }
        if normalized.contains("withings") {
            return "Open Device Sync and connect Withings account, then sync once to pull the latest readings."
        }
        return "Connect this source from Device Sync and run a manual sync to update your dashboard values."
    }
}

private func isOlderThan48Hours(_ raw: String?) -> Bool {
    guard let raw, let date = ISO8601DateFormatter().date(from: raw) else { return true }
    return Date().timeIntervalSince(date) >= (48 * 60 * 60)
}
