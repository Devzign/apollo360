//
//  ActivitiesSummaryCard.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

struct ActivitiesSummaryCard: View {
    let days: [ActivityDay]
    let stats: [ActivityStat]
    let summaryNote: String
    let weeklyChangePercent: Int

    private var formattedChangePercentage: String {
        let prefix = weeklyChangePercent >= 0 ? "+" : ""
        return "\(prefix)\(weeklyChangePercent)%"
    }

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Activities")
                            .font(AppFont.display(size: 18, weight: .bold))
                            .foregroundStyle(AppColor.black)
                        Text("Your movement this week")
                            .font(AppFont.body(size: 13))
                            .foregroundStyle(AppColor.grey)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text(formattedChangePercentage)
                            .font(AppFont.body(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppColor.green)
                }

                ActivityBarChartView(days: days)
                    .frame(height: 120)

                HStack {
                    ForEach(days) { day in
                        Text(day.label)
                            .font(AppFont.body(size: 11))
                            .foregroundStyle(AppColor.grey)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(stats) { stat in
                        ActivityStatView(stat: stat)
                    }
                }

                Text(summaryNote)
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundStyle(AppColor.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(AppColor.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

private struct ActivityBarChartView: View {
    let days: [ActivityDay]
    @State private var animateBars = false

    var body: some View {
        let maxSteps = max(days.map { $0.steps }.max() ?? 1, 1)

        return HStack(alignment: .bottom, spacing: 14) {
            ForEach(days) { day in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(day.isActive ? AppColor.green : Color.black.opacity(0.08))
                    .frame(
                        width: 24,
                        height: barHeight(for: day, maxSteps: maxSteps)
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: animateBars)
            }
        }
        .onAppear { restartAnimation() }
        .onBecomeVisible { restartAnimation() }
        .onChange(of: days) { _, _ in restartAnimation() }
    }

    private func barHeight(for day: ActivityDay, maxSteps: Int) -> CGFloat {
        let target = CGFloat(max(12.0, (Double(day.steps) / Double(maxSteps)) * 100.0))
        return animateBars ? target : 8
    }

    private func restartAnimation() {
        animateBars = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateBars = true
        }
    }
}

private struct ActivityStatView: View {
    let stat: ActivityStat

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: stat.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(stat.tint)

            Text(stat.value)
                .font(AppFont.body(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.black)

            Text(stat.title)
                .font(AppFont.body(size: 11))
                .foregroundStyle(AppColor.grey)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ActivitiesSummaryCard(
        days: [
            ActivityDay(label: "M", steps: 8234, isActive: true),
            ActivityDay(label: "T", steps: 6521, isActive: true),
            ActivityDay(label: "W", steps: 4102, isActive: false),
            ActivityDay(label: "T", steps: 7845, isActive: true),
            ActivityDay(label: "F", steps: 9012, isActive: true),
            ActivityDay(label: "S", steps: 5234, isActive: true),
            ActivityDay(label: "S", steps: 3421, isActive: false)
        ],
        stats: [
            ActivityStat(value: "6,338", title: "Avg Steps", systemImage: "figure.walk", tint: AppColor.primary),
            ActivityStat(value: "5/7", title: "Active Days", systemImage: "checkmark.circle", tint: AppColor.green),
            ActivityStat(value: "1,775", title: "Calories", systemImage: "flame", tint: AppColor.yellow)
        ],
        summaryNote: "Great consistency! You've been active 5 out of 7 days.",
        weeklyChangePercent: 12
    )
    .padding()
}
