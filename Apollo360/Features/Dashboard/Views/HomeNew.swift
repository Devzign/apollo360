//
//  HomeNew.swift
//  Apollo360
//

import SwiftUI
import Combine

@MainActor
final class HomeNewViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    @Published var greeting: String = "Hello,"
    @Published var fullName: String = "User"
    @Published var mainGoal: String = ""
    @Published var pendingAssessments: Int = 0
    @Published var lookupCategories: [DashboardLookupCategory] = []

    @Published var nutritionPlans: [DashboardPlanItem] = []
    @Published var behaviorPlans: [DashboardPlanItem] = []
    @Published var fitnessPlans: [DashboardPlanItem] = []

    private let session: SessionManager
    private var pendingRequests = 0 {
        didSet { isLoading = pendingRequests > 0 }
    }

    init(session: SessionManager) {
        self.session = session
        load()
    }

    func load() {
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        errorMessage = nil
        fetchSummary(token: token)
        fetchActivityPlans(token: token)
        fetchMetricsLookup(token: token)
        fetchSurveys(token: token)
    }

    private func fetchSummary(token: String) {
        beginLoading()
        DashboardAPIService.shared.fetchHomeSummary(bearerToken: token) { [weak self] result in
            defer { self?.endLoading() }
            guard let self else { return }
            switch result {
            case .success(let payload):
                greeting = payload.patientProfile.greeting.isEmpty ? "Hello," : payload.patientProfile.greeting
                fullName = payload.patientProfile.fullName
                mainGoal = payload.mainHealthGoal
                pendingAssessments = payload.pendingAssessmentCount
            case .failure(let error):
                errorMessage = errorMessage ?? error.localizedDescription
            }
        }
    }

    private func fetchActivityPlans(token: String) {
        beginLoading()
        DashboardAPIService.shared.fetchHomeActivityPlans(bearerToken: token) { [weak self] result in
            defer { self?.endLoading() }
            guard let self else { return }
            switch result {
            case .success(let payload):
                nutritionPlans = payload.nutrition
                behaviorPlans = payload.behavior
                fitnessPlans = payload.fitness
            case .failure(let error):
                errorMessage = errorMessage ?? error.localizedDescription
                nutritionPlans = []
                behaviorPlans = []
                fitnessPlans = []
            }
        }
    }

    private func fetchMetricsLookup(token: String) {
        beginLoading()
        DashboardAPIService.shared.fetchHomeMetricsLookup(bearerToken: token) { [weak self] result in
            defer { self?.endLoading() }
            guard let self else { return }
            if case .failure(let error) = result {
                errorMessage = errorMessage ?? error.localizedDescription
            } else if case .success(let categories) = result {
                lookupCategories = categories
            }
        }
    }

    private func fetchSurveys(token: String) {
        beginLoading()
        FormsAPIService.shared.fetchSurveys(bearerToken: token) { [weak self] result in
            defer { self?.endLoading() }
            guard let self else { return }
            switch result {
            case .success(let surveys):
                pendingAssessments = surveys.filter { !$0.isCompleted }.count
            case .failure:
                break
            }
        }
    }

    private func beginLoading() {
        pendingRequests += 1
    }

    private func endLoading() {
        pendingRequests = max(0, pendingRequests - 1)
    }
}

struct HomeNew: View {
    @StateObject private var viewModel: HomeNewViewModel

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: HomeNewViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                goalCard
                headerCard
                targetDetailCard
                categorySection(title: "Nutrition", plans: viewModel.nutritionPlans)
                categorySection(title: "Behavior", plans: viewModel.behaviorPlans)
                categorySection(title: "Fitness", plans: viewModel.fitnessPlans)
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.95),
                    Color(red: 0.93, green: 0.95, blue: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .overlay(alignment: .center) {
            if viewModel.isLoading && viewModel.nutritionPlans.isEmpty && viewModel.behaviorPlans.isEmpty && viewModel.fitnessPlans.isEmpty {
                ProgressView("Loading Home...")
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            }
        }
        .refreshable {
            viewModel.load()
        }
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(AppColor.green.opacity(0.85))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(AppFont.body(size: 12, weight: .regular))
                    .foregroundColor(AppColor.grey)
                Text(viewModel.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "User" : viewModel.fullName)
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundColor(AppColor.black)
                    .lineLimit(1)
            }
            Spacer()
            if viewModel.pendingAssessments > 0 {
                Text("\(viewModel.pendingAssessments)")
                    .font(AppFont.body(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(AppColor.green))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
        )
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text("My Goal")
                    .font(AppFont.body(size: 13, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.9))
            }
            Text(viewModel.mainGoal.isEmpty ? "-" : viewModel.mainGoal)
                .font(AppFont.body(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.green.opacity(0.78), AppColor.green.opacity(0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var targetDetailCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Target Detail")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.85))
            if viewModel.lookupCategories.isEmpty {
                Text("-")
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundColor(AppColor.grey)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.lookupCategories) { category in
                            Text("\(category.category) (\(category.metrics.count))")
                                .font(AppFont.body(size: 12, weight: .semibold))
                                .foregroundColor(AppColor.color414141)
                                .padding(.horizontal, 12)
                                .frame(height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppColor.green.opacity(0.12), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.03), radius: 8, y: 4)
        )
    }

    @ViewBuilder
    private func categorySection(title: String, plans: [DashboardPlanItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 17))
                    .foregroundColor(AppColor.green)
                Text(title)
                    .font(AppFont.display(size: 17, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.85))
            }

            if plans.isEmpty {
                Text("No plans available.")
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.grey)
                    .padding(.vertical, 4)
            } else {
                ForEach(plans) { plan in
                    HomePlanCard(plan: plan)
                }
            }
        }
    }
}

private struct HomePlanCard: View {
    let plan: DashboardPlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(plan.planItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Plan" : plan.planItem)
                .font(AppFont.body(size: 19, weight: .semibold))
                .foregroundColor(AppColor.black)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(authorName)
                    .font(AppFont.body(size: 11, weight: .medium))
                    .foregroundColor(AppColor.black.opacity(0.78))
                Text("• \(daysAgoText)")
                    .font(AppFont.body(size: 11, weight: .regular))
                    .foregroundColor(AppColor.grey)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.grey.opacity(0.7))
            }

            if !plan.patientMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(plan.patientMessage)
                .font(AppFont.body(size: 13, weight: .regular))
                    .foregroundColor(AppColor.color414141)
            }

            if let first = plan.relatedContent.first {
                VStack(alignment: .leading, spacing: 4) {
                    if let viewingTime = first.viewingTime?.trimmingCharacters(in: .whitespacesAndNewlines), !viewingTime.isEmpty {
                        Text("\(viewingTime) mins read")
                            .font(AppFont.body(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 5).fill(AppColor.green)
                            )
                    }
                    Text(first.title)
                        .font(AppFont.body(size: 12, weight: .medium))
                        .foregroundColor(AppColor.black.opacity(0.85))
                        .lineLimit(2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.95))
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.green.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 4)
    }

    private var authorName: String {
        let value = plan.author?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "Unknown Author" : value
    }

    private var daysAgoText: String {
        let value = plan.daysAgo.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "0 days ago" : "\(value) days ago"
    }
}
