import SwiftUI

struct DoctorMeMetricCard: View {
    let metric: DashboardMetricCardModel
    let onTap: () -> Void
    let onInstructionTap: () -> Void

    private var isStale: Bool { isOlderThan48Hours(metric.lastSyncDateRaw) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                metricIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.title)
                        .font(AppFont.body(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 22 / 255, green: 31 / 255, blue: 37 / 255))
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))
                        Text(metric.lastSyncText)
                            .font(AppFont.body(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(red: 102 / 255, green: 119 / 255, blue: 128 / 255))
                }

                Spacer(minLength: 8)

                Button(action: onInstructionTap) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 91 / 255, green: 111 / 255, blue: 120 / 255))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(metric.latestValueText)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundColor(valueColor)
                Text(metric.unitText.isEmpty ? "-" : metric.unitText)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 91 / 255, green: 109 / 255, blue: 118 / 255))
                Spacer()
                statusBadge
            }
            .padding(.top, 10)

            HStack(spacing: 7) {
                Text("Source")
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 103 / 255, green: 119 / 255, blue: 128 / 255))
                Text(metric.sourceText)
                    .font(AppFont.body(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 47 / 255, green: 73 / 255, blue: 69 / 255))
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(Capsule().fill(Color(red: 236 / 255, green: 246 / 255, blue: 241 / 255)))
                Spacer()
            }
            .padding(.top, 8)

            HStack(spacing: 5) {
                Image(systemName: trendIsDown ? "chart.line.downtrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12, weight: .semibold))
                Text(metric.trendText)
                    .font(AppFont.body(size: 12, weight: .bold))
                Text("vs last reading")
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 112 / 255, green: 125 / 255, blue: 132 / 255))
            }
            .foregroundColor(metric.trendTint)
            .padding(.top, 7)

            DashboardMetricSparkline(points: metric.sparkline, lineColor: Color(red: 49 / 255, green: 158 / 255, blue: 103 / 255))
                .frame(height: 60)
                .padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 244, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(isStale ? Color(red: 255 / 255, green: 247 / 255, blue: 199 / 255) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(isStale ? Color(red: 255 / 255, green: 184 / 255, blue: 66 / 255) : Color(red: 229 / 255, green: 238 / 255, blue: 233 / 255), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 8, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture(perform: onTap)
    }

    private var metricIcon: some View {
        ZStack {
            Circle()
                .fill(isStale ? Color(red: 255 / 255, green: 220 / 255, blue: 145 / 255) : Color(red: 216 / 255, green: 248 / 255, blue: 232 / 255))
                .frame(width: 38, height: 38)
            Image(systemName: dashboardMetricIcon(for: metric.metricField))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isStale ? Color(red: 108 / 255, green: 75 / 255, blue: 25 / 255) : Color(red: 20 / 255, green: 91 / 255, blue: 73 / 255))
        }
    }

    private var statusBadge: some View {
        Text(metric.statusBadgeText)
            .font(AppFont.body(size: 11, weight: .bold))
            .foregroundColor(metric.statusBadgeTint)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(Capsule().fill(metric.statusBadgeBackground))
            .overlay(Capsule().stroke(metric.statusBadgeTint.opacity(0.18), lineWidth: 1))
    }

    private var trendIsDown: Bool { (metric.percentageChange ?? 0) < 0 }

    private var valueColor: Color {
        metric.statusBadgeText == "Optimal" ? Color(red: 14 / 255, green: 25 / 255, blue: 32 / 255) : Color(red: 247 / 255, green: 48 / 255, blue: 61 / 255)
    }
}
