//
//  DashboardViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stories: [DailyStory] = []
    @Published var isLoadingInsights: Bool = false
    @Published private(set) var isLoading: Bool = true
    @Published var insightError: String?
    @Published var wellnessMode: WellnessMode = .absolute
    @Published var currentScore: Int = 0
    @Published var previousScore: Int = 0
    @Published var progress: Double = 0
    @Published var wellnessMetrics: [WellnessMetric] = []
    @Published var changeValue: Int = 0
    @Published var insights: [InsightItem] = []
    @Published var cardioMetrics: [CardioMetric] = []
    @Published var activityDays: [ActivityDay] = []
    @Published var activityStats: [ActivityStat] = []
    @Published var activitySummaryNote: String = ""
    @Published var weeklyChangePercent: Int = 0

    private let session: SessionManager
    private var pendingLoads = 0 {
        didSet {
            isLoading = pendingLoads > 0
        }
    }
    private var relativeBreakdown: WellnessBreakdown = WellnessBreakdown(activity: 0, sleep: 0, heart: 0, nutrition: 0)
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    let greeting = "Good morning,"
    var userName: String {
        session.username ?? "Amit Sinha"
    }

    let snapshotTitle = "Your Daily Snapshot"
    let snapshotSubtitle = "Personalized stories generated from your data to help you understand trends and take simple, supportive actions."

    let wellnessTitle = "Wellness Overview"
    let wellnessDescription = "Your current wellness level based on activity, sleep, heart health, and nutrition patterns."

    var wellnessChange: Int {
        changeValue
    }

    var isWellnessImproving: Bool {
        changeValue >= 0
    }

    init(session: SessionManager) {
        self.session = session
        fetchDailyStories()
        fetchWellnessOverview()
        fetchApolloInsights()
        fetchCardiometabolicMetrics()
        fetchActivities()
    }

    private func fetchDailyStories() {
        guard let patientId = session.patientId,
              let token = session.accessToken else { return }

        beginLoading()
        DashboardAPIService.shared.fetchDashboardInsights(patientId: patientId, bearerToken: token) { [weak self] result in
            defer { self?.endLoading() }
            guard let self = self else { return }
            switch result {
            case .success(let payloads):
                self.stories = payloads.map(Self.story(from:))
                self.insightError = nil
            case .failure(let error):
                self.insightError = error.localizedDescription
            }
        }
    }

    private func fetchWellnessOverview() {
        guard let patientId = session.patientId,
              let token = session.accessToken else { return }

        beginLoading()
        DashboardAPIService.shared.fetchWellnessOverview(patientId: patientId, bearerToken: token, mode: .absolute) { [weak self] result in
            defer { self?.endLoading() }
            guard let self = self else { return }
            switch result {
            case .success(let payload):
                self.wellnessMode = WellnessMode(apiValue: payload.mode)
                self.currentScore = payload.overallScore
                self.progress = min(Double(payload.overallScore) / 100.0, 1.0)
                let currentBreakdown = Self.breakdown(from: payload.absolute)
                if let relative = payload.relative {
                    self.relativeBreakdown = Self.breakdown(from: relative)
                }
                self.updateMetrics(using: currentBreakdown)
                self.changeValue = self.currentScore - self.previousScore
            case .failure:
                break
            }
        }
    }

    private func fetchApolloInsights() {
        guard let patientId = session.patientId,
              let token = session.accessToken else { return }

        beginLoading()
        isLoadingInsights = true
        DashboardAPIService.shared.fetchApolloInsights(patientId: patientId, bearerToken: token) { [weak self] result in
            defer {
                self?.endLoading()
            }
            guard let self = self else { return }
            self.isLoadingInsights = false
            switch result {
            case .success(let payload):
                self.insights = payload.insights.enumerated().map { index, insight in
                    InsightItem(
                        id: insight.id,
                        title: insight.title,
                        detail: insight.description,
                        systemImage: "lightbulb",
                        iconURL: insight.iconUrl,
                        impact: Self.impact(for: index)
                    )
                }
                self.insightError = nil
            case .failure(let error):
                self.insightError = error.localizedDescription
            }
        }
    }

    private func fetchCardiometabolicMetrics() {
        guard let patientId = session.patientId,
              let token = session.accessToken else { return }

        beginLoading()
        DashboardAPIService.shared.fetchCardiometabolicMetrics(patientId: patientId, bearerToken: token) { [weak self] result in
            defer { self?.endLoading() }
            guard let self = self else { return }
            switch result {
            case .success(let payload):
                let mapped = payload.metrics.careTeamMetrics.values.sorted { $0.title < $1.title }.map { metric in
                    CardioMetric(
                        title: metric.title,
                        value: metric.value,
                        unit: metric.unit ?? "",
                        trend: metric.trend ?? "",
                        tint: self.tintColor(for: metric.tint),
                        sparkline: self.normalizedSparkline(metric.sparkline)
                    )
                }
                self.cardioMetrics = mapped.isEmpty ? Self.defaultCardioMetrics() : mapped
            case .failure:
                break
            }
        }
    }

    private func fetchActivities() {
        guard let patientId = session.patientId,
              let token = session.accessToken else { return }

        beginLoading()
        DashboardAPIService.shared.fetchActivities(patientId: patientId, bearerToken: token) { [weak self] result in
            defer { self?.endLoading() }
            guard let self = self else { return }
            switch result {
            case .success(let payload):
                self.activityDays = payload.chart.map { entry in
                    ActivityDay(label: entry.day, steps: entry.value, isActive: entry.isActive)
                }
                self.activityStats = [
                    ActivityStat(value: self.formatNumber(payload.summary.avgSteps), title: "Avg Steps", systemImage: "figure.walk", tint: AppColor.primary),
                    ActivityStat(value: "\(payload.summary.activeDays)/7", title: "Active Days", systemImage: "checkmark.circle", tint: AppColor.green),
                    ActivityStat(value: self.formatNumber(payload.summary.calories), title: "Calories", systemImage: "flame", tint: AppColor.yellow)
                ]
                self.activitySummaryNote = payload.message
                self.weeklyChangePercent = payload.weeklyChangePercent
            case .failure:
                break
            }
        }
    }

    private func updateMetrics(using current: WellnessBreakdown) {
        wellnessMetrics = Self.metrics(current: current, previous: relativeBreakdown)
    }

    private func formatNumber(_ value: Int) -> String {
        let number = NSNumber(value: value)
        return numberFormatter.string(from: number) ?? "\(value)"
    }

    private func tintColor(for value: String?) -> Color {
        guard let value = value?.lowercased() else { return AppColor.primary }
        switch value {
        case "green": return AppColor.green
        case "red": return AppColor.red
        case "yellow": return AppColor.yellow
        case "blue": return AppColor.blue
        case "primary": return AppColor.primary
        default: return AppColor.primary
        }
    }

    private func normalizedSparkline(_ values: [Double]?) -> [Double] {
        if let existing = values, !existing.isEmpty {
            return existing
        }
        return [0.5, 0.5, 0.5]
    }

    private func beginLoading() {
        pendingLoads += 1
    }

    private func endLoading() {
        pendingLoads = max(pendingLoads - 1, 0)
    }

    private static func metrics(current: WellnessBreakdown, previous: WellnessBreakdown) -> [WellnessMetric] {
        [
            WellnessMetric(title: "Activity", current: current.activity, previous: previous.activity, tint: AppColor.green),
            WellnessMetric(title: "Sleep", current: current.sleep, previous: previous.sleep, tint: AppColor.blue),
            WellnessMetric(title: "Heart", current: current.heart, previous: previous.heart, tint: AppColor.red),
            WellnessMetric(title: "Nutrition", current: current.nutrition, previous: previous.nutrition, tint: AppColor.yellow)
        ]
    }

    private static func breakdown(from absolute: WellnessAbsoluteBreakdown) -> WellnessBreakdown {
        WellnessBreakdown(
            activity: absolute.activity,
            sleep: absolute.sleep,
            heart: absolute.heart,
            nutrition: absolute.nutrition
        )
    }

    private static func breakdown(from relative: WellnessRelativeBreakdown) -> WellnessBreakdown {
        WellnessBreakdown(
            activity: relative.activity,
            sleep: relative.sleep,
            heart: relative.heart,
            nutrition: relative.nutrition
        )
    }

    private static func impact(for index: Int) -> InsightImpact {
        switch index {
        case 0: return .positive
        case 1: return .neutral
        default: return .attention
        }
    }

    private static func story(from payload: DashboardInsightPayload) -> DailyStory {
        DailyStory(
            title: payload.category,
            tint: color(for: payload.category),
            hasUpdate: true,
            isViewed: false,
            iconURL: payload.iconUrl,
            headline: payload.title,
            detail: payload.subtitle,
            recommendation: payload.recommendation
        )
    }

    private static func color(for category: String) -> Color {
        switch category.lowercased() {
        case "rpm":
            return AppColor.green
        case "activity":
            return AppColor.blue
        case "labs":
            return AppColor.primary
        case "medications":
            return AppColor.yellow
        default:
            return AppColor.secondary
        }
    }

    private static func defaultCardioMetrics() -> [CardioMetric] {
        [
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
    }

    func logout() {
        guard let token = session.accessToken else {
            session.clearSession()
            return
        }

        APIClient.shared.logout(bearerToken: token) { [weak self] _ in
            self?.session.clearSession()
        }
    }
}
