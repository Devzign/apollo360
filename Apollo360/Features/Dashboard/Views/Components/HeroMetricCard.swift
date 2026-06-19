import SwiftUI

struct HeroMetricCard: View {
    enum Style { case primaryHero, secondaryHero }

    let metric: DashboardMetricCardModel
    let style: Style
    let onTap: () -> Void
    let onInstructionTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 38, height: 38)
                    Image(systemName: dashboardMetricIcon(for: metric.metricField))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.88))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.title)
                        .font(AppFont.body(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))
                        Text(metric.lastSyncText)
                            .font(AppFont.body(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.72))
                }

                Spacer(minLength: 8)

                Button(action: onInstructionTap) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.82))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(metric.latestValueText)
                    .font(.system(size: 33, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(metric.unitText)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                Spacer()
                Text(metric.statusBadgeText)
                    .font(AppFont.body(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .frame(height: 27)
                    .background(Capsule().fill(Color.white.opacity(0.17)))
            }
            .padding(.top, 10)

            DashboardMetricSparkline(
                points: metric.sparkline,
                lineColor: Color(red: 36 / 255, green: 165 / 255, blue: 106 / 255),
                showsFill: false
            )
            .frame(height: 42)
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 214, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: style == .primaryHero
                    ? [Color(red: 58 / 255, green: 105 / 255, blue: 255 / 255), Color(red: 82 / 255, green: 69 / 255, blue: 215 / 255)]
                    : [Color(red: 54 / 255, green: 101 / 255, blue: 248 / 255), Color(red: 79 / 255, green: 66 / 255, blue: 209 / 255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color(red: 59 / 255, green: 82 / 255, blue: 200 / 255).opacity(0.15), radius: 12, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}
