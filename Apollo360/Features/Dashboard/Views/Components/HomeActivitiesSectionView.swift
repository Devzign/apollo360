import SwiftUI

struct HomeActivitiesSectionView: View {
    let gauges: DashboardSummaryGauges
    let submittedActivities: [SubmittedActivity]
    let onLogTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.48, blue: 0.74), Color(red: 0.30, green: 0.65, blue: 0.82)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.20)).frame(width: 44, height: 44)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activities")
                            .font(AppFont.display(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Your progress at a glance")
                            .font(AppFont.body(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.82))
                    }
                    Spacer()
                    Button(action: onLogTap) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Log")
                                .font(AppFont.body(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.18, green: 0.48, blue: 0.74))
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(Capsule().fill(Color.white))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
            .cornerRadius(16)
            .shadow(color: Color(red: 0.18, green: 0.48, blue: 0.74).opacity(0.28), radius: 12, y: 4)

            let gaugeItems: [(String, String, DashboardGauge, Color)] = [
                ("Nutrition", "fork.knife", gauges.nutrition, Color(red: 0.22, green: 0.68, blue: 0.42)),
                ("Behavior", "brain.head.profile", gauges.behavior, Color(red: 0.38, green: 0.50, blue: 0.88)),
                ("Fitness", "figure.run", gauges.fitness, Color(red: 0.92, green: 0.52, blue: 0.18))
            ]
            HStack(spacing: 10) {
                ForEach(gaugeItems, id: \.0) { name, icon, gauge, accent in
                    activityRingTile(name: name, icon: icon, gauge: gauge, accent: accent)
                }
            }

            if !submittedActivities.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundColor(AppColor.green)
                        Text("Logged this session")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                        Spacer()
                        Text("\(submittedActivities.count) entr\(submittedActivities.count == 1 ? "y" : "ies")")
                            .font(AppFont.body(size: 12, weight: .medium))
                            .foregroundColor(AppColor.grey)
                    }
                    ForEach(submittedActivities) { act in
                        let catColor = categoryAccent(act.category)
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(catColor.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: categoryIcon(act.category))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(catColor)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(act.category)
                                        .font(AppFont.body(size: 10, weight: .semibold))
                                        .foregroundColor(catColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(catColor.opacity(0.12)))
                                    Text(act.metricType)
                                        .font(AppFont.body(size: 13, weight: .semibold))
                                        .foregroundColor(AppColor.color414141)
                                }
                                HStack(spacing: 6) {
                                    Text("\(act.value.formatted()) \(act.unit)")
                                        .font(AppFont.body(size: 12, weight: .medium))
                                        .foregroundColor(catColor)
                                    if !act.note.isEmpty {
                                        Text("· \(act.note)")
                                            .font(AppFont.body(size: 12, weight: .regular))
                                            .foregroundColor(AppColor.grey)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            Spacer()
                            Text(act.date.formatted(date: .omitted, time: .shortened))
                                .font(AppFont.body(size: 11, weight: .medium))
                                .foregroundColor(AppColor.grey)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(catColor.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16).fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
                )
            } else {
                VStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color(red: 0.18, green: 0.48, blue: 0.74).opacity(0.08)).frame(width: 72, height: 72)
                        Image(systemName: "bolt.slash.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 0.18, green: 0.48, blue: 0.74).opacity(0.35))
                    }
                    Text("No activities logged yet")
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.color414141)
                    Text("Tap \"Log\" above to record your activity.")
                        .font(AppFont.body(size: 13, weight: .regular))
                        .foregroundColor(AppColor.grey)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
            }
        }
    }

    @ViewBuilder
    private func activityRingTile(name: String, icon: String, gauge: DashboardGauge, accent: Color) -> some View {
        let progress = gauge.targetValue > 0 ? min(gauge.metricValue / gauge.targetValue, 1.0) : 0.0
        let valueText = gauge.metricValue == 0 && gauge.units.isEmpty
            ? "—" : "\(Int(gauge.metricValue))\(gauge.units.isEmpty ? "" : " \(gauge.units)")"

        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(accent.opacity(0.12), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 60, height: 60)
                    .animation(.easeInOut(duration: 0.6), value: progress)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accent)
            }
            VStack(spacing: 2) {
                Text(valueText)
                    .font(AppFont.body(size: 12, weight: .bold))
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(name)
                    .font(AppFont.body(size: 11, weight: .medium))
                    .foregroundColor(AppColor.color414141.opacity(0.70))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.10), lineWidth: 1)
        )
    }

    private func categoryAccent(_ category: String) -> Color {
        switch category.lowercased() {
        case "nutrition": return Color(red: 0.22, green: 0.68, blue: 0.42)
        case "behavior": return Color(red: 0.38, green: 0.50, blue: 0.88)
        case "fitness": return Color(red: 0.92, green: 0.52, blue: 0.18)
        default: return AppColor.green
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "nutrition": return "fork.knife"
        case "behavior": return "brain.head.profile"
        case "fitness": return "figure.run"
        default: return "bolt.fill"
        }
    }
}
