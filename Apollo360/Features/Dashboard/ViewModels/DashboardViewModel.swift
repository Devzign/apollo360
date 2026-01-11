import Combine
import Foundation
import SwiftUI

final class DashboardViewModel: ObservableObject {
    @Published var wellnessMode: WellnessMode

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private let wellnessOverview: WellnessOverviewResponse

    let greeting = "Good morning,"
    let userName = "Amit Sinha"

    let snapshotTitle = "Your Daily Snapshot"
    let snapshotSubtitle = "Personalized stories generated from your data to help you understand trends and take simple, supportive actions."

    let wellnessTitle = "Wellness Overview"
    let wellnessDescription = "Your current wellness level based on activity, sleep, heart health, and nutrition patterns."
    let currentScore: Int
    let previousScore: Int
    let stories: [DailyStory]
    let wellnessMetrics: [WellnessMetric]
    let insights: [InsightItem]

    init() {
        let overview = DashboardAPIMock.wellnessOverview
        self.wellnessOverview = overview
        self.wellnessMode = overview.mode
        self.currentScore = overview.overallScore
        self.previousScore = overview.relative.lastWeek

        self.stories = DashboardAPIMock.insightSnapshots.map { snapshot in
            DailyStory(
                title: snapshot.category,
                tint: Self.color(for: snapshot.category),
                hasUpdate: true,
                isViewed: false,
                iconURL: snapshot.iconURL,
                headline: snapshot.title,
                detail: snapshot.subtitle,
                recommendation: snapshot.recommendation
            )
        }

        self.wellnessMetrics = Self.metrics(from: overview.relative.breakdown)

        self.insights = DashboardAPIMock.apolloInsights.enumerated().map { index, detail in
            InsightItem(
                id: detail.id,
                title: detail.title,
                detail: detail.description,
                iconURL: detail.iconURL,
                impact: Self.impact(for: index)
            )
        }
    }

    private static func metrics(from breakdown: WellnessBreakdown) -> [WellnessMetric] {
        [
            WellnessMetric(title: "Activity", current: breakdown.activity, previous: 0, tint: AppColor.green),
            WellnessMetric(title: "Sleep", current: breakdown.sleep, previous: 0, tint: AppColor.blue),
            WellnessMetric(title: "Heart", current: breakdown.heart, previous: 0, tint: AppColor.red),
            WellnessMetric(title: "Nutrition", current: breakdown.nutrition, previous: 0, tint: AppColor.yellow)
        ]
    }

    private static func color(for category: String) -> Color {
        switch category.lowercased() {
        case "rpm":
            return AppColor.green
        case "activity":
            return AppColor.blue
        case "labs":
            return AppColor.blue
        case "medications":
            return AppColor.yellow
        case "mood":
            return AppColor.primary
        default:
            return AppColor.secondary
        }
    }

    private static func impact(for index: Int) -> InsightImpact {
        switch index {
        case 0:
            return .positive
        case 2:
            return .attention
        default:
            return .neutral
        }
    }

    let cardioMetrics: [CardioMetric] = [
        CardioMetric(
            title: "Blood Pressure",
            value: "121/77",
            unit: "mmHg",
            trend: "+1% from last week",
            tint: AppColor.red,
            sparkline: [0.62, 0.64, 0.61, 0.66, 0.63, 0.65, 0.64]
        ),
        CardioMetric(
            title: "Resting Heart Rate",
            value: "65",
            unit: "bpm",
            trend: "-3 bpm from last week",
            tint: AppColor.green,
            sparkline: [0.56, 0.52, 0.54, 0.51, 0.49, 0.5, 0.48]
        ),
        CardioMetric(
            title: "Glucose",
            value: "96",
            unit: "mg/dL",
            trend: "Stable this week",
            tint: AppColor.yellow,
            sparkline: [0.48, 0.52, 0.5, 0.47, 0.49, 0.48, 0.46]
        )
    ]

    let activityDays: [ActivityDay] = [
        ActivityDay(label: "M", steps: 8234, isActive: true),
        ActivityDay(label: "T", steps: 6521, isActive: true),
        ActivityDay(label: "W", steps: 4102, isActive: false),
        ActivityDay(label: "T", steps: 7845, isActive: true),
        ActivityDay(label: "F", steps: 9012, isActive: true),
        ActivityDay(label: "S", steps: 5234, isActive: true),
        ActivityDay(label: "S", steps: 3421, isActive: false)
    ]

    var wellnessChange: Int {
        currentScore - previousScore
    }

    var isWellnessImproving: Bool {
        wellnessChange >= 0
    }

    var activityAverageSteps: Int {
        guard !activityDays.isEmpty else { return 0 }
        let total = activityDays.reduce(0) { $0 + $1.steps }
        return total / activityDays.count
    }

    var activityActiveDays: Int {
        activityDays.filter { $0.isActive }.count
    }

    var activityCalories: Int {
        let total = activityDays.reduce(0) { $0 + $1.steps }
        return Int(Double(total) * 0.04)
    }

    var activityStats: [ActivityStat] {
        [
            ActivityStat(value: formatNumber(activityAverageSteps), title: "Avg Steps", systemImage: "figure.walk", tint: AppColor.primary),
            ActivityStat(value: "\(activityActiveDays)/7", title: "Active Days", systemImage: "checkmark.circle", tint: AppColor.green),
            ActivityStat(value: formatNumber(activityCalories), title: "Calories", systemImage: "flame", tint: AppColor.yellow)
        ]
    }

    var activitySummaryNote: String {
        "Great consistency! You have been active \(activityActiveDays) out of 7 days."
    }

    var wellnessProgress: Double {
        Double(currentScore) / 100.0
    }

    private func formatNumber(_ value: Int) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
