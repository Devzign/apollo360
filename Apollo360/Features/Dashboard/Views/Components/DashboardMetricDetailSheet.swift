import SwiftUI
import Charts

struct DashboardMetricDetailSheet: View {
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
