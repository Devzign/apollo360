import SwiftUI

struct HeroMetricCard: View {
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
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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
