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

struct HomeNew: View {
    @StateObject private var viewModel: HomeNewViewModel
    @State private var isFeelingOpen = false
    @State private var isActivitiesOpen = false

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: HomeNewViewModel(session: session))
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    goalCard
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
            .background(LinearGradient(colors: [Color(red: 0.95, green: 0.96, blue: 0.95), Color(red: 0.93, green: 0.95, blue: 0.94)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())

            if viewModel.isLoading && viewModel.nutritionPlans.isEmpty && viewModel.behaviorPlans.isEmpty && viewModel.fitnessPlans.isEmpty {
                ProgressView("Loading Home...")
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            }

            if isFeelingOpen || isActivitiesOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isFeelingOpen = false
                        isActivitiesOpen = false
                    }
            }

            if isFeelingOpen {
                FeelingSheet(viewModel: viewModel) {
                    isFeelingOpen = false
                }
                    .frame(maxWidth: 390)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 165)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(3)
            }

            if isActivitiesOpen {
                ActivitiesSheet(viewModel: viewModel) {
                    isActivitiesOpen = false
                }
                    .frame(maxWidth: 390)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 165)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(3)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isFeelingOpen)
        .animation(.easeInOut(duration: 0.18), value: isActivitiesOpen)
        .refreshable { viewModel.load() }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text("My Goal")
                    .font(AppFont.body(size: 20, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.93))
            }
            Text(viewModel.mainGoal.isEmpty ? "-" : viewModel.mainGoal)
                .font(AppFont.body(size: 16, weight: .medium))
                .foregroundColor(.white)

            HStack(spacing: 0) {
                Button("I’m Feeling") { isFeelingOpen = true }
                    .buttonStyle(HomePillButtonStyle(isDark: false))
                Divider().frame(height: 20).overlay(Color.white.opacity(0.35))
                Button("Activities") { isActivitiesOpen = true }
                    .buttonStyle(HomePillButtonStyle(isDark: true))
            }
            .padding(4)
            .background(Capsule().fill(AppColor.green.opacity(0.76)))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(LinearGradient(colors: [AppColor.green.opacity(0.86), AppColor.green.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)))
    }

    private var targetDetailCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Target Detail")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.85))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.lookupCategories) { category in
                        Text("\(category.category) (\(category.metrics.count))")
                            .font(AppFont.body(size: 12, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColor.green.opacity(0.12), lineWidth: 1)))
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.92)).shadow(color: Color.black.opacity(0.03), radius: 8, y: 4))
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
                ForEach(plans) { plan in HomePlanCard(plan: plan) }
            }
        }
    }
}

private struct HomePillButtonStyle: ButtonStyle {
    let isDark: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .background((isDark ? Color.black.opacity(0.18) : Color.clear).clipShape(Capsule()))
            .clipShape(Capsule())
    }
}

// MARK: - Shared inline dropdown component
private struct InlineDropdown: View {
    let placeholder: String
    let options: [String]
    @Binding var selected: String
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 0) {
            // Trigger button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isOpen.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Text(selected.isEmpty ? placeholder : selected)
                        .font(AppFont.body(size: 15, weight: .regular))
                        .foregroundColor(selected.isEmpty ? Color(red: 0.7, green: 0.7, blue: 0.7) : AppColor.color414141)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.color414141.opacity(0.7))
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isOpen)
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isOpen ? AppColor.green.opacity(0.55) : Color(red: 0.82, green: 0.82, blue: 0.82), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Options list
            if isOpen {
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selected = option
                                isOpen = false
                            }
                        } label: {
                            HStack {
                                Text(option)
                                    .font(AppFont.body(size: 15, weight: .regular))
                                    .foregroundColor(AppColor.color414141)
                                Spacer()
                                if selected == option {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppColor.green)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(selected == option ? AppColor.green.opacity(0.05) : Color.white)
                        }
                        .buttonStyle(.plain)

                        if option != options.last {
                            Divider().padding(.horizontal, 12)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                .zIndex(20)
            }
        }
        .zIndex(isOpen ? 20 : 0)
    }
}

// MARK: - I’m Feeling Sheet
private struct FeelingSheet: View {
    @ObservedObject var viewModel: HomeNewViewModel
    let onClose: () -> Void
    @State private var selectedSymptom = ""
    @State private var note = ""

    private let options = ["Chest pain", "Palpitations", "Trouble breathing", "Dizzy", "Fatigue", "Pain", "Anxious", "Happy", "Sad"]
    private var recentSymptoms: [DashboardRecentSymptom] { Array(viewModel.recentSymptoms.prefix(3)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 14) {
                Text("I’m Feeling")
                    .font(AppFont.display(size: 22, weight: .bold))
                    .foregroundColor(AppColor.color414141)
                Divider()
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    // Recent symptom chips
                    if !recentSymptoms.isEmpty {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                            spacing: 10
                        ) {
                            ForEach(recentSymptoms.indices, id: \.self) { idx in
                                let item = recentSymptoms[idx]
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.symptoms)
                                        .font(AppFont.body(size: 12, weight: .semibold))
                                        .foregroundColor(AppColor.color414141)
                                        .lineLimit(1)
                                    Text(formattedDate(item.createdAt))
                                        .font(AppFont.body(size: 11, weight: .bold))
                                        .foregroundColor(AppColor.green)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color(red: 0.86, green: 0.96, blue: 0.88)))
                            }
                        }
                    }

                    // Feeling dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How you are feeling")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.color414141)

                        InlineDropdown(placeholder: "Select", options: options, selected: $selectedSymptom)
                    }

                    // OR divider
                    HStack(spacing: 12) {
                        Rectangle().fill(Color(red: 0.85, green: 0.85, blue: 0.85)).frame(height: 1)
                        Text("or")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Rectangle().fill(Color(red: 0.85, green: 0.85, blue: 0.85)).frame(height: 1)
                    }

                    // Free-text note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe how you’re feeling")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.color414141)

                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("Type here max 25 characters...")
                                    .font(AppFont.body(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.72, green: 0.72, blue: 0.72))
                                    .padding(.top, 12)
                                    .padding(.leading, 14)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $note)
                                .font(AppFont.body(size: 14, weight: .regular))
                                .frame(height: 100)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .scrollContentBackground(.hidden)
                                .onChange(of: note) { newValue in
                                    if newValue.count > 25 { note = String(newValue.prefix(25)) }
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(red: 0.82, green: 0.82, blue: 0.82), lineWidth: 1)
                        )
                    }

                    // Action buttons
                    VStack(spacing: 10) {
                        Button("Save") {
                            let selected = selectedSymptom.isEmpty ? [] : [selectedSymptom]
                            viewModel.saveFeeling(selected: selected, note: note) { success in
                                if success { onClose() }
                            }
                        }
                        .buttonStyle(HomeActionButtonStyle(
                            isPrimary: true,
                            isDisabled: viewModel.isSavingFeeling || (selectedSymptom.isEmpty && note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        ))

                        Button("Cancel") { onClose() }
                            .buttonStyle(HomeActionButtonStyle(isPrimary: false, isDisabled: viewModel.isSavingFeeling))
                    }

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(AppFont.body(size: 12, weight: .medium))
                            .foregroundColor(AppColor.red)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
            }
        }
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
        .shadow(color: Color.black.opacity(0.18), radius: 28, x: 0, y: 10)
        .frame(maxWidth: 390)
        .frame(maxHeight: min(UIScreen.main.bounds.height * 0.80, 640))
    }

    private func formattedDate(_ raw: String) -> String {
        let input = ISO8601DateFormatter()
        if let date = input.date(from: raw) {
            let output = DateFormatter()
            output.dateFormat = "MM/dd/yyyy"
            return output.string(from: date)
        }
        return raw
    }
}

// MARK: - Activities Sheet
private struct ActivitiesSheet: View {
    @ObservedObject var viewModel: HomeNewViewModel
    let onClose: () -> Void

    @State private var selectedCategory = ""
    @State private var selectedMetricId: Int?
    @State private var notes = ""
    @State private var valueText = ""
    @State private var dropdownSelection = ""

    private var categories: [DashboardLookupCategory] { viewModel.lookupCategories }
    private var selectedCategoryModel: DashboardLookupCategory? { categories.first(where: { $0.category == selectedCategory }) }
    private var selectedMetric: DashboardLookupMetric? { selectedCategoryModel?.metrics.first(where: { $0.id == selectedMetricId }) }
    private var metricOptions: [String] { selectedCategoryModel?.metrics.map { $0.type } ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 14) {
                Text("Activities")
                    .font(AppFont.display(size: 22, weight: .bold))
                    .foregroundColor(AppColor.color414141)
                Divider()
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    Text("Please share your activities")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .foregroundColor(AppColor.color414141)

                    // Category radio buttons
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(categories) { category in
                            Button {
                                selectedCategory = category.category
                                selectedMetricId = nil
                                dropdownSelection = ""
                                valueText = ""
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .stroke(selectedCategory == category.category ? AppColor.green : Color(red: 0.75, green: 0.75, blue: 0.75), lineWidth: 1.5)
                                            .frame(width: 22, height: 22)
                                        if selectedCategory == category.category {
                                            Circle()
                                                .fill(AppColor.green)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                    Text(category.category)
                                        .font(AppFont.body(size: 15, weight: .medium))
                                        .foregroundColor(AppColor.color414141)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Metric dropdown
                    InlineDropdown(
                        placeholder: "Select",
                        options: metricOptions,
                        selected: $dropdownSelection
                    )
                    .onChange(of: dropdownSelection) { newValue in
                        selectedMetricId = selectedCategoryModel?.metrics.first(where: { $0.type == newValue })?.id
                        valueText = ""
                    }

                    // Notes field
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Activities Notes")
                                .font(AppFont.body(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.72, green: 0.72, blue: 0.72))
                                .padding(.top, 12)
                                .padding(.leading, 14)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $notes)
                            .font(AppFont.body(size: 14, weight: .regular))
                            .frame(height: 90)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .scrollContentBackground(.hidden)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(red: 0.82, green: 0.82, blue: 0.82), lineWidth: 1)
                    )

                    // Units value field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedMetric?.unit.isEmpty == false ? selectedMetric!.unit : "Units")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.color414141)

                        TextField("", text: $valueText)
                            .keyboardType(.decimalPad)
                            .font(AppFont.body(size: 15, weight: .regular))
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(red: 0.82, green: 0.82, blue: 0.82), lineWidth: 1)
                            )
                    }

                    // Action buttons
                    VStack(spacing: 10) {
                        Button("Save") {
                            guard let metric = selectedMetric else { return }
                            viewModel.saveActivity(metric: metric, valueText: valueText, note: notes) { success in
                                if success { onClose() }
                            }
                        }
                        .buttonStyle(HomeActionButtonStyle(
                            isPrimary: true,
                            isDisabled: viewModel.isSavingActivity || selectedMetric == nil || valueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ))

                        Button("Cancel") { onClose() }
                            .buttonStyle(HomeActionButtonStyle(isPrimary: false, isDisabled: viewModel.isSavingActivity))
                    }

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(AppFont.body(size: 12, weight: .medium))
                            .foregroundColor(AppColor.red)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
            }
        }
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
        .shadow(color: Color.black.opacity(0.18), radius: 28, x: 0, y: 10)
        .frame(maxWidth: 390)
        .frame(maxHeight: min(UIScreen.main.bounds.height * 0.82, 660))
        .onAppear {
            if selectedCategory.isEmpty {
                selectedCategory = categories.first?.category ?? ""
            }
        }
    }
}

private struct HomeActionButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .font(AppFont.body(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 12).fill(isPrimary ? AppColor.green : AppColor.color414141))
            .opacity(isDisabled ? 0.55 : (configuration.isPressed ? 0.85 : 1))
    }
}

private struct WrapChipsView: View {
    let items: [String]
    @Binding var selection: Set<String>

    var body: some View {
        FlowLayout(items: items, spacing: 8) { value in
            Button(value) {
                if selection.contains(value) { selection.remove(value) } else { selection.insert(value) }
            }
            .font(AppFont.body(size: 13, weight: .medium))
            .foregroundColor(selection.contains(value) ? .white : AppColor.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(selection.contains(value) ? AppColor.green : Color(red: 0.92, green: 0.96, blue: 0.92)))
        }
    }
}

private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(items: Data, spacing: CGFloat, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: spacing, alignment: .leading)], alignment: .leading, spacing: spacing) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
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
                            .background(RoundedRectangle(cornerRadius: 5).fill(AppColor.green))
                    }
                    Text(first.title)
                        .font(AppFont.body(size: 12, weight: .medium))
                        .foregroundColor(AppColor.black.opacity(0.85))
                        .lineLimit(2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.95)))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColor.green.opacity(0.12), lineWidth: 1))
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
