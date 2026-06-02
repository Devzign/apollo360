import SwiftUI
import Combine

@MainActor
final class HomeNewViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isSavingFeeling = false
    @Published private(set) var isSavingActivity = false
    @Published var errorMessage: String?

    @Published var greeting: String = "Hello,"
    @Published var fullName: String = "User"
    @Published var mainGoal: String = ""
    @Published var pendingAssessments: Int = 0
    @Published var lookupCategories: [DashboardLookupCategory] = []
    @Published var recentSymptoms: [DashboardRecentSymptom] = []

    @Published var nutritionPlans: [DashboardPlanItem] = []
    @Published var behaviorPlans: [DashboardPlanItem] = []
    @Published var fitnessPlans: [DashboardPlanItem] = []

    @Published var gauges: DashboardSummaryGauges = DashboardSummaryGauges(
        nutrition: .empty, behavior: .empty, fitness: .empty
    )
    @Published var submittedActivities: [SubmittedActivity] = []

    private let session: SessionManager
    private var pendingRequests = 0 { didSet { isLoading = pendingRequests > 0 } }

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

    func saveFeeling(selected: [String], note: String, completion: @escaping (Bool) -> Void) {
        guard let token = session.accessToken else { completion(false); return }
        let cleanSelected = selected.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanSelected.isEmpty || !cleanNote.isEmpty else { completion(false); return }

        isSavingFeeling = true
        DashboardAPIService.shared.createDashboardSymptoms(
            request: DashboardCreateSymptomsRequest(symptoms: cleanSelected, symptom: cleanNote),
            bearerToken: token
        ) { [weak self] result in
            guard let self else { return }
            isSavingFeeling = false
            switch result {
            case .success:
                fetchSummary(token: token)
                completion(true)
            case .failure(let error):
                errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }

    func saveActivity(metric: DashboardLookupMetric,
                      categoryName: String,
                      valueText: String,
                      note: String,
                      completion: @escaping (Bool) -> Void) {
        guard let token = session.accessToken else { completion(false); return }
        let cleanValue = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(cleanValue) else { completion(false); return }

        isSavingActivity = true
        DashboardAPIService.shared.createDashboardActivity(
            request: DashboardCreateActivityRequest(
                metricId: metric.id,
                value: value,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                unit: metric.unit.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            bearerToken: token
        ) { [weak self] result in
            guard let self else { return }
            isSavingActivity = false
            switch result {
            case .success:
                submittedActivities.insert(
                    SubmittedActivity(
                        category: categoryName,
                        metricType: metric.type,
                        value: value,
                        unit: metric.unit,
                        note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                        date: Date()
                    ),
                    at: 0
                )
                completion(true)
            case .failure(let error):
                errorMessage = error.localizedDescription
                completion(false)
            }
        }
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
                recentSymptoms = payload.recentSymptoms
                gauges = payload.gauges
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
            switch result {
            case .success(let categories):
                lookupCategories = categories
            case .failure(let error):
                errorMessage = errorMessage ?? error.localizedDescription
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

    private func beginLoading() { pendingRequests += 1 }
    private func endLoading() { pendingRequests = max(0, pendingRequests - 1) }
}
