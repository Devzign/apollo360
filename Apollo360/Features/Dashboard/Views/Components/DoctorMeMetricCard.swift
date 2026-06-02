import SwiftUI

struct DoctorMeMetricCard: View {
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
