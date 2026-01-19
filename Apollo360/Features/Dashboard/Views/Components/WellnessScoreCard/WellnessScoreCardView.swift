import SwiftUI

struct WellnessScoreCardView: View {
    let title: String
    let description: String
    let currentScore: Int
    let previousScore: Int
    let progress: Double
    let metrics: [WellnessMetric]
    let isImproving: Bool
    let changeValue: Int
    @Binding var mode: WellnessMode
    @State private var isShowingBreakdown = false

    var body: some View {
        DashboardCard {
            VStack(alignment: .center, spacing: 6) {
                HStack(alignment: .center) {
                    Text(title)
                        .font(AppFont.display(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    WellnessModeToggle(selected: $mode)
                }
                .padding(.bottom, 10)

                if mode == .absolute {
                    absoluteView
                } else {
                    relativeView
                }
            }
        }
        .sheet(isPresented: $isShowingBreakdown) {
            ScoreBreakdownView(
                score: currentScore,
                mode: mode,
                metrics: metrics
            )
        }
    }

    private var absoluteView: some View {
        VStack(spacing: 16) {
            FitnessGaugeView(value: Double(currentScore))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    isShowingBreakdown = true
                }

            Text(description)
                .font(AppFont.body(size: 13))
                .foregroundStyle(AppColor.grey)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: .infinity)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics) { metric in
                    WellnessMetricRow(metric: metric)
                }
            }
        }
    }

    private var relativeView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Last Week")
                        .font(AppFont.body(size: 12))
                        .foregroundStyle(AppColor.grey)
                    Text("\(previousScore)")
                        .font(AppFont.display(size: 28, weight: .bold))
                        .foregroundStyle(AppColor.grey)
                }

                TrendIndicatorView(isImproving: isImproving)

                VStack(spacing: 6) {
                    Text("This Week")
                        .font(AppFont.body(size: 12, weight: .medium))
                        .foregroundStyle(AppColor.black)
                    Text("\(currentScore)")
                        .font(AppFont.display(size: 32, weight: .bold))
                        .foregroundStyle(isImproving ? AppColor.green : AppColor.red)
                }
            }

            WellnessChangeBadge(isImproving: isImproving, changeValue: changeValue)

            Text(isImproving
                 ? "Great progress! Your wellness has improved compared to your recent baseline."
                 : "Small changes add up. Focus on one area to improve this week.")
                .font(AppFont.body(size: 13))
                .foregroundStyle(AppColor.grey)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics) { metric in
                    WellnessDeltaRow(metric: metric)
                }
            }
        }
    }
}

private struct WellnessScoreCardPreview: View {
    @State private var mode: WellnessMode = .absolute

    var body: some View {
        WellnessScoreCardView(
            title: "Wellness Overview",
            description: "Your current wellness level based on activity, sleep, heart health, and nutrition patterns.",
            currentScore: 82,
            previousScore: 74,
            progress: 0.82,
            metrics: [
                WellnessMetric(title: "Activity", current: 78, previous: 71, tint: AppColor.green),
                WellnessMetric(title: "Sleep", current: 85, previous: 80, tint: AppColor.blue),
                WellnessMetric(title: "Heart", current: 72, previous: 75, tint: AppColor.red),
                WellnessMetric(title: "Nutrition", current: 80, previous: 76, tint: AppColor.yellow)
            ],
            isImproving: true,
            changeValue: 8,
            mode: $mode
        )
    }
}

#Preview {
    WellnessScoreCardPreview()
        .padding()
        .background(Color.black.opacity(0.02))
}
