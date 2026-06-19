import Charts
import SwiftUI

struct DashboardMetricDetailSheet: View {
    let metric: DashboardMetricCardModel
    let session: SessionManager

    @Environment(\.dismiss) private var dismiss
    @State private var detailPoints: [Double] = []
    @State private var detailAverage = "--"
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(metric.title)
                    .font(AppFont.body(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 22 / 255, green: 31 / 255, blue: 37 / 255))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 25))
                        .foregroundColor(Color(red: 35 / 255, green: 172 / 255, blue: 114 / 255))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Current Value")
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 95 / 255, green: 116 / 255, blue: 123 / 255))
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(metric.latestValueText)
                        .font(.system(size: 31, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 247 / 255, green: 48 / 255, blue: 61 / 255))
                    Text(metric.unitText)
                        .font(AppFont.body(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 91 / 255, green: 109 / 255, blue: 118 / 255))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 241 / 255, green: 250 / 255, blue: 245 / 255)))
            .padding(.top, 16)

            Text("Last 365 Days Trend")
                .font(AppFont.body(size: 14, weight: .bold))
                .padding(.top, 18)
            Text("Last 365 days average: \(detailAverage)")
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundColor(Color(red: 95 / 255, green: 116 / 255, blue: 123 / 255))
                .padding(.top, 2)

            chart
                .padding(.top, 10)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 22)
        .background(Color(red: 247 / 255, green: 255 / 255, blue: 250 / 255))
        .task { await loadChart() }
    }

    @ViewBuilder
    private var chart: some View {
        if isLoading && detailPoints.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(chartBackground)
        } else if detailPoints.isEmpty {
            Text("No chart data")
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundColor(AppColor.grey)
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(chartBackground)
        } else {
            Chart(Array(detailPoints.enumerated()), id: \.offset) { index, value in
                LineMark(x: .value("Day", index), y: .value("Value", value))
                    .interpolationMethod(.linear)
                    .foregroundStyle(Color(red: 46 / 255, green: 158 / 255, blue: 101 / 255))
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine().foregroundStyle(Color.clear)
                    AxisValueLabel {
                        if let index = value.as(Int.self) {
                            Text(monthLabel(for: index))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.7, dash: [3]))
                        .foregroundStyle(Color.gray.opacity(0.22))
                    AxisValueLabel()
                }
            }
            .frame(height: 250)
            .padding(14)
            .background(chartBackground)
        }
    }

    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(red: 218 / 255, green: 233 / 255, blue: 225 / 255)))
    }

    private func monthLabel(for index: Int) -> String {
        let labels = ["Jun", "Aug", "Nov", "Jan", "Apr"]
        guard !detailPoints.isEmpty else { return "" }
        let bucket = min(Int(Double(index) / Double(max(detailPoints.count - 1, 1)) * 4), 4)
        return labels[bucket]
    }

    private func loadChart() async {
        guard let patientId = session.patientId,
              let token = session.accessToken else { return }
        isLoading = true
        await withCheckedContinuation { continuation in
            MetricsAPIService.shared.fetchUserMetricSeries(
                metricField: metric.metricField,
                patientId: patientId,
                selectedRange: "365",
                source: .rpm,
                bearerToken: token
            ) { result in
                if case .success(let payload) = result {
                    Task { @MainActor in
                        detailPoints = payload.points
                        detailAverage = payload.averageValueText
                    }
                }
                continuation.resume()
            }
        }
        isLoading = false
    }
}
