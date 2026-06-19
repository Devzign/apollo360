//
//  DashboardViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var doctorMetricCards: [DashboardMetricCardModel] = []
    @Published var myMetricCards: [DashboardMetricCardModel] = []
    @Published var homeMetricsError: String?
    @Published var stories: [DailyStory] = []
    @Published var isLoadingInsights: Bool = false
    @Published private(set) var isLoading: Bool = false
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
    @Published private(set) var isHeaderSyncing: Bool = false
    @Published var syncErrorMessage: String?

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
        self.cardioMetrics = Self.defaultCardioMetrics()
        refreshDashboard()
    }

    func refreshDashboard() {
        fetchHomeMetrics()
    }

    func syncFromHeader() async {
        guard !isHeaderSyncing else { return }

        let username = (session.username ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else {
            syncErrorMessage = "Apollo username is missing. Log in again before syncing."
            return
        }

        do {
            isHeaderSyncing = true
            let config = try ApolloSyncConfig.fromInfoPlist()
            let service = ApolloSyncService(config: config)
            let encodedUsername = Self.encodedUsername(from: username)
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "ios-device"

            print("🚀 [Dashboard] Registering device with Validic (no HealthKit upload from here)")
            let validicUser = try await service.registerValidicUser(
                encodedPatientUsername: encodedUsername,
                deviceId: deviceId
            )
            print("✅ [Dashboard] Device registered | validic_user=\(validicUser.id) sources=\(validicUser.sources?.count ?? 0)")

            // Cache the Validic user so DeviceSyncView can immediately show
            // the marketplace URL and device list without re-running the handshake.
            if let data = try? JSONEncoder().encode(validicUser) {
                UserDefaults.standard.set(data, forKey: "Apollo360.validicUser")
            }

            refreshDashboard()
        } catch {
            print("❌ [Dashboard] Header sync failed: \(error.localizedDescription)")
            syncErrorMessage = error.localizedDescription
        }

        isHeaderSyncing = false
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

    private func fetchHomeMetrics() {
        guard let patientId = session.patientId,
              let token = session.accessToken else { return }

        homeMetricsError = nil
        beginLoading()
        DashboardAPIService.shared.fetchDashboardMetrics(patientId: patientId, bearerToken: token, selectionType: .doctor) { [weak self] result in
            defer { self?.endLoading() }
            guard let self = self else { return }
            switch result {
            case .success(let payload):
                self.doctorMetricCards = self.mapDashboardMetricCards(from: payload.metrics, selectionType: .doctor)
            case .failure(let error):
                self.homeMetricsError = error.localizedDescription
                self.doctorMetricCards = []
            }
        }

        beginLoading()
        DashboardAPIService.shared.fetchDashboardMetrics(patientId: patientId, bearerToken: token, selectionType: .me) { [weak self] result in
            defer { self?.endLoading() }
            guard let self = self else { return }
            switch result {
            case .success(let payload):
                self.myMetricCards = self.mapDashboardMetricCards(from: payload.metrics, selectionType: .me)
            case .failure(let error):
                self.homeMetricsError = self.homeMetricsError ?? error.localizedDescription
                self.myMetricCards = []
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

        DashboardAPIService.shared.fetchCardiometabolicMetrics(patientId: patientId, bearerToken: token) { [weak self] result in
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
                self.cardioMetrics = Self.defaultCardioMetrics()
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

    private func mapDashboardMetricCards(from payloads: [DashboardMetricPayload],
                                         selectionType: DashboardMetricSelectionType) -> [DashboardMetricCardModel] {
        payloads.enumerated().map { index, payload in
            let latestValue = payload.latestValue ?? 0
            let averageValue = payload.averageValue
            let percentageChange = payload.percentageChange
            let syncStatus = payload.syncStatus ?? "unknown"
            let defaultUnit = payload.defaultUnit?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let source = payload.source?
                .replacingOccurrences(of: "_", with: " ")
                .capitalized ?? "Unknown"
            let isHero = selectionType == .doctor && index == 0

            return DashboardMetricCardModel(
                id: payload.metricId,
                metricField: payload.metricField,
                title: payload.description,
                latestValueText: formatMetricValue(latestValue),
                latestValue: latestValue,
                factor: payload.factor ?? 1,
                optimalFrom: payload.optimalFrom,
                optimalThru: payload.optimalThru,
                unitText: defaultUnit,
                sourceText: source,
                syncStatus: syncStatus,
                trendText: formatTrendText(percentageChange),
                percentageChange: percentageChange,
                trendTint: trendTint(for: percentageChange),
                statusBadgeText: statusBadgeText(for: payload),
                statusBadgeTint: statusBadgeTint(for: payload),
                statusBadgeBackground: statusBadgeBackground(for: payload),
                lastSyncText: relativeSyncText(from: payload.lastSyncDate),
                lastSyncDateRaw: payload.lastSyncDate,
                isHero: isHero,
                sparkline: sparklineSeed(for: payload.metricField, anchor: latestValue, average: averageValue),
            )
        }
    }

    private func formatMetricValue(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    private func formatTrendText(_ change: Double?) -> String {
        guard let change else { return "0%" }
        return String(format: "%@%.2f%%", change >= 0 ? "+" : "", change)
    }

    private func trendTint(for change: Double?) -> Color {
        guard let change else { return AppColor.green }
        return change < 0 ? AppColor.red : AppColor.green
    }

    private func metricStatus(for payload: DashboardMetricPayload) -> String {
        guard let latestValue = payload.latestValue,
              let optimalFrom = payload.optimalFrom,
              let optimalThru = payload.optimalThru else {
            return "Optimal"
        }
        let factor = payload.factor ?? 1
        let normalizedValue = latestValue * factor
        if normalizedValue >= optimalFrom && normalizedValue <= optimalThru {
            return "Optimal"
        }
        return normalizedValue > optimalThru ? "High" : "Low"
    }

    private func statusBadgeText(for payload: DashboardMetricPayload) -> String {
        metricStatus(for: payload)
    }

    private func statusBadgeTint(for payload: DashboardMetricPayload) -> Color {
        switch metricStatus(for: payload) {
        case "High":
            return AppColor.red
        case "Low":
            return AppColor.yellow
        default:
            return AppColor.green
        }
    }

    private func statusBadgeBackground(for payload: DashboardMetricPayload) -> Color {
        switch metricStatus(for: payload) {
        case "High":
            return AppColor.red.opacity(0.12)
        case "Low":
            return AppColor.yellow.opacity(0.18)
        default:
            return AppColor.green.opacity(0.14)
        }
    }

    private func relativeSyncText(from isoDate: String?) -> String {
        guard let isoDate else { return "0 min ago" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()

        let date = formatter.date(from: isoDate) ?? fallbackFormatter.date(from: isoDate)
        guard let date else { return "0 min ago" }

        let interval = max(Int(Date().timeIntervalSince(date)), 0)
        if interval < 3600 {
            let minutes = max(interval / 60, 1)
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        }
        if interval < 86_400 {
            let hours = interval / 3600
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        let days = interval / 86_400
        return days == 1 ? "1 day ago" : "\(days) days ago"
    }

    private func sparklineSeed(for metricField: String, anchor: Double, average: Double?) -> [Double] {
        let base = max(anchor, average ?? anchor, 1)
        let hashSeed = abs(metricField.hashValue % 7)
        let deltas: [Double] = [
            0.18, 0.42, 0.27, 0.58, 0.34, 0.51, 0.29
        ]
        return deltas.enumerated().map { index, delta in
            let wobble = Double((hashSeed + index) % 5) * 0.04
            return (base * max(0.12, delta + wobble)).rounded() / 100
        }
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

    private static func encodedUsername(from username: String) -> String {
        if let data = Data(base64Encoded: username),
           let decoded = String(data: data, encoding: .utf8),
           !decoded.isEmpty {
            return username
        }

        return Data(username.utf8).base64EncodedString()
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
