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

    // Gauges (nutrition / behavior / fitness progress summary)
    @Published var gauges: DashboardSummaryGauges = DashboardSummaryGauges(
        nutrition: .empty, behavior: .empty, fitness: .empty
    )
    // In-session log of submitted activities
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
                // Record locally so the Activities tab can display it immediately
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

// MARK: - Supporting types

struct SubmittedActivity: Identifiable {
    let id = UUID()
    let category: String
    let metricType: String
    let value: Double
    let unit: String
    let note: String
    let date: Date
}

enum HomeSection: String, CaseIterable {
    case plans      = "Plans"
    case feeling    = "I'm Feeling"
    case activities = "Activities"
}

// MARK: - HomeNew

struct HomeNew: View {
    @StateObject private var viewModel: HomeNewViewModel
    @State private var isFeelingOpen = false
    @State private var isActivitiesOpen = false
    @State private var homeSection: HomeSection = .plans

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: HomeNewViewModel(session: session))
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    goalCard
                    homeSectionSwitcher
                    switch homeSection {
                    case .plans:
                        targetDetailCard
                        categorySection(title: "Nutrition", plans: viewModel.nutritionPlans)
                        categorySection(title: "Behavior", plans: viewModel.behaviorPlans)
                        categorySection(title: "Fitness", plans: viewModel.fitnessPlans)
                    case .feeling:
                        feelingSectionView
                    case .activities:
                        activitiesSectionView
                    }
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
        }
        .refreshable { viewModel.load() }
        // ── I'm Feeling sheet ──────────────────────────────────────────────
        .sheet(isPresented: $isFeelingOpen) {
            NavigationView {
                FeelingSheet(viewModel: viewModel,
                             onSaved: {
                                 isFeelingOpen = false
                                 withAnimation(.easeInOut(duration: 0.25)) { homeSection = .feeling }
                             },
                             onCancel: { isFeelingOpen = false })
            }
            .navigationViewStyle(.stack)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .modifier(PresentationCornerRadiusModifier(radius: 26))
        }
        // ── Activities sheet ───────────────────────────────────────────────
        .sheet(isPresented: $isActivitiesOpen) {
            NavigationView {
                ActivitiesSheet(viewModel: viewModel,
                                onSaved: {
                                    isActivitiesOpen = false
                                    withAnimation(.easeInOut(duration: 0.25)) { homeSection = .activities }
                                },
                                onCancel: { isActivitiesOpen = false })
            }
            .navigationViewStyle(.stack)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .modifier(PresentationCornerRadiusModifier(radius: 26))
        }
    }

    // MARK: - Section Switcher

    // MARK: - Segment switcher (animated sliding pill)
    private var homeSectionSwitcher: some View {
        GeometryReader { geo in
            let count  = CGFloat(HomeSection.allCases.count)
            let tabW   = geo.size.width / count
            let selIdx = CGFloat(HomeSection.allCases.firstIndex(of: homeSection) ?? 0)

            ZStack(alignment: .leading) {
                // Sliding green pill
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.green)
                    .frame(width: tabW - 4, height: geo.size.height - 4)
                    .offset(x: selIdx * tabW + 2, y: 2)
                    .animation(.spring(response: 0.32, dampingFraction: 0.78), value: homeSection)
                    .shadow(color: AppColor.green.opacity(0.30), radius: 8, y: 3)

                // Tab labels
                HStack(spacing: 0) {
                    ForEach(HomeSection.allCases, id: \.self) { section in
                        let isSelected = homeSection == section
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                homeSection = section
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: sectionIcon(section))
                                    .font(.system(size: 11, weight: .semibold))
                                Text(section.rawValue)
                                    .font(AppFont.body(size: 13, weight: isSelected ? .semibold : .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(isSelected ? .white : AppColor.color414141.opacity(0.50))
                            .frame(maxWidth: .infinity)
                            .frame(height: geo.size.height)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.18), value: isSelected)
                    }
                }
            }
        }
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
        )
    }

    private func sectionIcon(_ section: HomeSection) -> String {
        switch section {
        case .plans:      return "list.bullet.rectangle"
        case .feeling:    return "heart.fill"
        case .activities: return "bolt.fill"
        }
    }

    // MARK: - I'm Feeling Section

    private var feelingSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Gradient banner header
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [AppColor.green, AppColor.green.opacity(0.72)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.20)).frame(width: 44, height: 44)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I'm Feeling")
                            .font(AppFont.display(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text(viewModel.recentSymptoms.isEmpty
                             ? "Nothing logged yet"
                             : "\(viewModel.recentSymptoms.count) entr\(viewModel.recentSymptoms.count == 1 ? "y" : "ies") logged")
                            .font(AppFont.body(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.82))
                    }
                    Spacer()
                    Button {
                        withAnimation { isFeelingOpen = true }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Log")
                                .font(AppFont.body(size: 13, weight: .semibold))
                        }
                        .foregroundColor(AppColor.green)
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
            .shadow(color: AppColor.green.opacity(0.28), radius: 12, y: 4)

            if viewModel.recentSymptoms.isEmpty {
                // Empty state
                VStack(spacing: 14) {
                    ZStack {
                        Circle().fill(AppColor.green.opacity(0.08)).frame(width: 72, height: 72)
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 30))
                            .foregroundColor(AppColor.green.opacity(0.40))
                    }
                    Text("Nothing logged yet")
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.color414141)
                    Text("Tap \"Log\" above to record how you're feeling.")
                        .font(AppFont.body(size: 13, weight: .regular))
                        .foregroundColor(AppColor.grey)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
            } else {
                // Symptom cards
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.recentSymptoms.enumerated()), id: \.offset) { _, symptom in
                        let (icon, accent) = symptomMeta(symptom.symptoms)
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(accent.opacity(0.13))
                                    .frame(width: 46, height: 46)
                                Image(systemName: icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(accent)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(symptom.symptoms)
                                    .font(AppFont.body(size: 15, weight: .semibold))
                                    .foregroundColor(AppColor.color414141)
                                Text(feelingSmartDate(symptom.createdAt))
                                    .font(AppFont.body(size: 12, weight: .regular))
                                    .foregroundColor(AppColor.grey)
                            }
                            Spacer()
                            // Subtle accent pill
                            Text(symptomCategory(symptom.symptoms))
                                .font(AppFont.body(size: 10, weight: .semibold))
                                .foregroundColor(accent)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(accent.opacity(0.12)))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(accent.opacity(0.12), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    /// Returns (SF-symbol, accent color) for a given symptom string.
    private func symptomMeta(_ s: String) -> (String, Color) {
        let lower = s.lowercased()
        if lower.contains("chest")    { return ("heart.fill",             Color(red: 0.90, green: 0.25, blue: 0.28)) }
        if lower.contains("palpit")   { return ("waveform.path.ecg",      Color(red: 0.88, green: 0.35, blue: 0.28)) }
        if lower.contains("breath")   { return ("lungs.fill",             Color(red: 0.30, green: 0.55, blue: 0.90)) }
        if lower.contains("dizz")     { return ("tornado",                Color(red: 0.62, green: 0.40, blue: 0.90)) }
        if lower.contains("fatigue") ||
           lower.contains("tired")   { return ("battery.25percent",       Color(red: 0.85, green: 0.62, blue: 0.18)) }
        if lower.contains("pain")     { return ("cross.circle.fill",      Color(red: 0.85, green: 0.28, blue: 0.38)) }
        if lower.contains("happy")    { return ("face.smiling.fill",      Color(red: 0.25, green: 0.72, blue: 0.42)) }
        if lower.contains("sad")      { return ("cloud.rain.fill",        Color(red: 0.35, green: 0.52, blue: 0.88)) }
        if lower.contains("anxious")  { return ("bolt.fill",              Color(red: 0.90, green: 0.58, blue: 0.18)) }
        if lower.contains("nausea") ||
           lower.contains("sick")    { return ("allergens",               Color(red: 0.50, green: 0.72, blue: 0.38)) }
        return ("heart.text.square.fill", AppColor.green)
    }

    private func symptomCategory(_ s: String) -> String {
        let lower = s.lowercased()
        if lower.contains("chest") || lower.contains("palpit") || lower.contains("breath") { return "Cardiac" }
        if lower.contains("pain") || lower.contains("dizz") { return "Physical" }
        if lower.contains("happy") || lower.contains("sad") || lower.contains("anxious") { return "Mental" }
        if lower.contains("fatigue") || lower.contains("tired") { return "Energy" }
        return "General"
    }

    /// Smart date: "Today", "Yesterday", "Mon 15 May" — no time for date-only entries.
    private func feelingSmartDate(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse
        var parsed: Date?
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        parsed = isoFull.date(from: trimmed)
        if parsed == nil {
            isoFull.formatOptions = [.withInternetDateTime]
            parsed = isoFull.date(from: trimmed)
        }
        if parsed == nil {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.timeZone = TimeZone(identifier: "UTC")
            parsed = df.date(from: String(trimmed.prefix(10)))
        }
        guard let d = parsed else { return String(trimmed.prefix(10)) }

        // Decide if time matters (not midnight UTC)
        let isDateOnly = trimmed.count <= 10
            || trimmed.hasSuffix("T00:00:00.000Z")
            || trimmed.hasSuffix("T00:00:00Z")

        let cal = Calendar.current
        if cal.isDateInToday(d)     { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }

        let df = DateFormatter()
        df.dateFormat = isDateOnly ? "EEE, d MMM yyyy" : "EEE, d MMM yyyy · h:mm a"
        return df.string(from: d)
    }

    // MARK: - Activities Section

    private var activitiesSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Gradient banner header
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
                    Button {
                        withAnimation { isActivitiesOpen = true }
                    } label: {
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

            // 3-up gauge ring row
            let gaugeItems: [(String, String, DashboardGauge, Color)] = [
                ("Nutrition", "fork.knife",         viewModel.gauges.nutrition,
                 Color(red: 0.22, green: 0.68, blue: 0.42)),
                ("Behavior",  "brain.head.profile", viewModel.gauges.behavior,
                 Color(red: 0.38, green: 0.50, blue: 0.88)),
                ("Fitness",   "figure.run",          viewModel.gauges.fitness,
                 Color(red: 0.92, green: 0.52, blue: 0.18)),
            ]
            HStack(spacing: 10) {
                ForEach(gaugeItems, id: \.0) { name, icon, gauge, accent in
                    activityRingTile(name: name, icon: icon, gauge: gauge, accent: accent)
                }
            }

            // Recently submitted activities this session
            if !viewModel.submittedActivities.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundColor(AppColor.green)
                        Text("Logged this session")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                        Spacer()
                        Text("\(viewModel.submittedActivities.count) entr\(viewModel.submittedActivities.count == 1 ? "y" : "ies")")
                            .font(AppFont.body(size: 12, weight: .medium))
                            .foregroundColor(AppColor.grey)
                    }
                    ForEach(viewModel.submittedActivities) { act in
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
                // Empty state
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
        let progress = gauge.targetValue > 0
            ? min(gauge.metricValue / gauge.targetValue, 1.0) : 0.0
        let valueText = gauge.metricValue == 0 && gauge.units.isEmpty
            ? "—" : "\(Int(gauge.metricValue))\(gauge.units.isEmpty ? "" : " \(gauge.units)")"

        VStack(spacing: 10) {
            // Arc ring
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
        case "behavior":  return Color(red: 0.38, green: 0.50, blue: 0.88)
        case "fitness":   return Color(red: 0.92, green: 0.52, blue: 0.18)
        default:          return AppColor.green
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "nutrition": return "fork.knife"
        case "behavior":  return "brain.head.profile"
        case "fitness":   return "figure.run"
        default:          return "bolt.fill"
        }
    }

    // MARK: - Goal card

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: greeting + name
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.greeting)
                        .font(AppFont.body(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.80))
                    Text(viewModel.fullName)
                        .font(AppFont.display(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                // Quick pending badge
                if viewModel.pendingAssessments > 0 {
                    VStack(spacing: 2) {
                        Text("\(viewModel.pendingAssessments)")
                            .font(AppFont.body(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("pending")
                            .font(AppFont.body(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Divider with goal
            if !viewModel.mainGoal.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Text(viewModel.mainGoal)
                        .font(AppFont.body(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.88))
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }

            // Action buttons row
            HStack(spacing: 1) {
                Button {
                    withAnimation { isFeelingOpen = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13))
                        Text("I’m Feeling")
                            .font(AppFont.body(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.white.opacity(0.15))
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1, height: 26)

                Button {
                    withAnimation { isActivitiesOpen = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13))
                        Text("Activities")
                            .font(AppFont.body(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.black.opacity(0.12))
                }
                .buttonStyle(.plain)
            }
            .background(Color.black.opacity(0.10))
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.60, blue: 0.40),
                    AppColor.green,
                    Color(red: 0.28, green: 0.55, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: AppColor.green.opacity(0.32), radius: 14, y: 5)
    }

    private var targetDetailCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.green)
                Text("Target Metrics")
                    .font(AppFont.body(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.85))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.lookupCategories) { category in
                        let accent = categoryAccent(category.category)
                        HStack(spacing: 6) {
                            Image(systemName: categoryIcon(category.category))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(accent)
                            Text("\(category.category) (\(category.metrics.count))")
                                .font(AppFont.body(size: 12, weight: .semibold))
                                .foregroundColor(AppColor.color414141)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accent.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
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

// MARK: - iOS-version-safe presentationCornerRadius modifier
private struct PresentationCornerRadiusModifier: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCornerRadius(radius)
        } else {
            content
        }
    }
}

// MARK: - I’m Feeling Sheet
private struct FeelingSheet: View {
    @ObservedObject var viewModel: HomeNewViewModel
    let onSaved: () -> Void
    let onCancel: () -> Void
    @State private var selectedSymptom = ""
    @State private var note = ""

    private let options = ["Chest pain", "Palpitations", "Trouble breathing", "Dizzy", "Fatigue", "Pain", "Anxious", "Happy", "Sad"]
    private let chipColors: [Color] = [
        Color(red: 1.0, green: 0.87, blue: 0.87),
        Color(red: 0.87, green: 0.94, blue: 1.0),
        Color(red: 0.95, green: 0.88, blue: 1.0),
        Color(red: 0.88, green: 0.97, blue: 0.91),
        Color(red: 1.0, green: 0.94, blue: 0.84)
    ]
    private var recentSymptoms: [DashboardRecentSymptom] { Array(viewModel.recentSymptoms.prefix(4)) }
    private var canSave: Bool {
        !viewModel.isSavingFeeling && (!selectedSymptom.isEmpty || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Gradient header
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [AppColor.green.opacity(0.88), AppColor.green.opacity(0.60)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 76)

                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.22)).frame(width: 38, height: 38)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I’m Feeling")
                            .font(AppFont.display(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Log how you’re feeling right now")
                            .font(AppFont.body(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.82))
                    }
                    Spacer()
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.20)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
            .cornerRadius(0)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Recent symptom chips
                    if !recentSymptoms.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColor.green)
                                Text("Recent")
                                    .font(AppFont.body(size: 13, weight: .semibold))
                                    .foregroundColor(AppColor.color414141)
                            }
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                                spacing: 8
                            ) {
                                ForEach(recentSymptoms.indices, id: \.self) { idx in
                                    let item = recentSymptoms[idx]
                                    let bg = chipColors[idx % chipColors.count]
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(AppColor.green.opacity(0.65))
                                            .frame(width: 7, height: 7)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.symptoms)
                                                .font(AppFont.body(size: 12, weight: .semibold))
                                                .foregroundColor(AppColor.color414141)
                                                .lineLimit(1)
                                            Text(formattedDate(item.createdAt))
                                                .font(AppFont.body(size: 10, weight: .medium))
                                                .foregroundColor(AppColor.green.opacity(0.85))
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(bg)
                                    )
                                }
                            }
                        }
                    }

                    // Feeling dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Label("How you are feeling", systemImage: "face.smiling")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                        InlineDropdown(placeholder: "Select a symptom", options: options, selected: $selectedSymptom)
                    }

                    // OR divider
                    HStack(spacing: 10) {
                        Rectangle().fill(Color(red: 0.88, green: 0.88, blue: 0.88)).frame(height: 1)
                        Text("or type below")
                            .font(AppFont.body(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.62, green: 0.62, blue: 0.62))
                            .fixedSize()
                        Rectangle().fill(Color(red: 0.88, green: 0.88, blue: 0.88)).frame(height: 1)
                    }

                    // Free-text note
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Describe how you’re feeling", systemImage: "pencil.line")
                                .font(AppFont.body(size: 13, weight: .semibold))
                                .foregroundColor(AppColor.color414141)
                            Spacer()
                            Text("\(note.count)/25")
                                .font(AppFont.body(size: 11, weight: .medium))
                                .foregroundColor(note.count >= 25 ? AppColor.green : Color(red: 0.70, green: 0.70, blue: 0.70))
                        }
                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("Type here (max 25 characters)…")
                                    .font(AppFont.body(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.72, green: 0.72, blue: 0.72))
                                    .padding(.top, 12)
                                    .padding(.leading, 14)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $note)
                                .font(AppFont.body(size: 14, weight: .regular))
                                .frame(height: 88)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .scrollContentBackground(.hidden)
                                .onChange(of: note) { newValue in
                                    if newValue.count > 25 { note = String(newValue.prefix(25)) }
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(red: 0.84, green: 0.84, blue: 0.84), lineWidth: 1)
                                )
                        )
                    }

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                            Text(error)
                                .font(AppFont.body(size: 12, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.07)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }

            // Sticky footer
            Divider()
            VStack(spacing: 10) {
                Button {
                    let selected = selectedSymptom.isEmpty ? [] : [selectedSymptom]
                    viewModel.saveFeeling(selected: selected, note: note) { success in
                        if success { onSaved() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSavingFeeling {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        }
                        Text(viewModel.isSavingFeeling ? "Saving…" : "Save")
                    }
                }
                .buttonStyle(HomeActionButtonStyle(isPrimary: true, isDisabled: !canSave))

            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 30, x: 0, y: 8)
        .frame(maxWidth: 390)
    }

    private func formattedDate(_ raw: String) -> String {
        let input = ISO8601DateFormatter()
        if let date = input.date(from: raw) {
            let output = DateFormatter()
            output.dateFormat = "MM/dd/yyyy"
            return output.string(from: date)
        }
        // fallback: show as-is but trim the time portion if ISO-like
        return String(raw.prefix(10))
    }
}

// MARK: - Activities Sheet
private struct ActivitiesSheet: View {
    @ObservedObject var viewModel: HomeNewViewModel
    let onSaved: () -> Void
    let onCancel: () -> Void

    @State private var selectedCategory = ""
    @State private var selectedMetricId: Int?
    @State private var notes = ""
    @State private var valueText = ""
    @State private var dropdownSelection = ""

    private var categories: [DashboardLookupCategory] { viewModel.lookupCategories }
    private var selectedCategoryModel: DashboardLookupCategory? { categories.first(where: { $0.category == selectedCategory }) }
    private var selectedMetric: DashboardLookupMetric? { selectedCategoryModel?.metrics.first(where: { $0.id == selectedMetricId }) }
    private var metricOptions: [String] { selectedCategoryModel?.metrics.map { $0.type } ?? [] }
    private var canSave: Bool {
        !viewModel.isSavingActivity && selectedMetric != nil && !valueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Category icon mapping
    private func iconFor(_ category: String) -> String {
        switch category.lowercased() {
        case "nutrition": return "fork.knife"
        case "behavior":  return "brain.head.profile"
        case "fitness":   return "figure.run"
        default:          return "chart.bar.fill"
        }
    }

    // Category accent color
    private func colorFor(_ category: String) -> Color {
        switch category.lowercased() {
        case "nutrition": return Color(red: 0.25, green: 0.70, blue: 0.45)
        case "behavior":  return Color(red: 0.40, green: 0.52, blue: 0.88)
        case "fitness":   return Color(red: 0.92, green: 0.55, blue: 0.22)
        default:          return AppColor.green
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Gradient header
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color(red: 0.20, green: 0.52, blue: 0.76), Color(red: 0.28, green: 0.68, blue: 0.80)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 76)

                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.22)).frame(width: 38, height: 38)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activities")
                            .font(AppFont.display(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Log your daily activity")
                            .font(AppFont.body(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.82))
                    }
                    Spacer()
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.20)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Category pills (horizontal)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Category", systemImage: "tag")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(categories) { category in
                                    let isSelected = selectedCategory == category.category
                                    let accent = colorFor(category.category)
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.18)) {
                                            selectedCategory = category.category
                                            selectedMetricId = nil
                                            dropdownSelection = ""
                                            valueText = ""
                                        }
                                    } label: {
                                        HStack(spacing: 7) {
                                            Image(systemName: iconFor(category.category))
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(isSelected ? .white : accent)
                                            Text(category.category)
                                                .font(AppFont.body(size: 14, weight: .semibold))
                                                .foregroundColor(isSelected ? .white : AppColor.color414141)
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 40)
                                        .background(
                                            Capsule().fill(isSelected ? accent : accent.opacity(0.10))
                                        )
                                        .overlay(
                                            Capsule().stroke(isSelected ? Color.clear : accent.opacity(0.30), lineWidth: 1)
                                        )
                                        .shadow(color: isSelected ? accent.opacity(0.35) : .clear, radius: 6, y: 3)
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.18), value: isSelected)
                                }
                            }
                        }
                    }

                    // Metric type dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Activity type", systemImage: "list.bullet")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)

                        InlineDropdown(
                            placeholder: selectedCategory.isEmpty ? "Select a category first" : "Select type",
                            options: metricOptions,
                            selected: $dropdownSelection
                        )
                        .onChange(of: dropdownSelection) { newValue in
                            selectedMetricId = selectedCategoryModel?.metrics.first(where: { $0.type == newValue })?.id
                            valueText = ""
                        }
                        .opacity(selectedCategory.isEmpty ? 0.50 : 1)
                        .disabled(selectedCategory.isEmpty)
                    }

                    // Value (units) field
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            selectedMetric?.unit.isEmpty == false ? selectedMetric!.unit : "Value / Units",
                            systemImage: "number"
                        )
                        .font(AppFont.body(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.color414141)

                        TextField("Enter value", text: $valueText)
                            .keyboardType(.decimalPad)
                            .font(AppFont.body(size: 15, weight: .regular))
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color(red: 0.84, green: 0.84, blue: 0.84), lineWidth: 1)
                                    )
                            )
                    }

                    // Notes field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (optional)", systemImage: "square.and.pencil")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)

                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Add any additional notes…")
                                    .font(AppFont.body(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.72, green: 0.72, blue: 0.72))
                                    .padding(.top, 12)
                                    .padding(.leading, 14)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $notes)
                                .font(AppFont.body(size: 14, weight: .regular))
                                .frame(height: 80)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .scrollContentBackground(.hidden)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(red: 0.84, green: 0.84, blue: 0.84), lineWidth: 1)
                                )
                        )
                    }

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                            Text(error)
                                .font(AppFont.body(size: 12, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.07)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }

            // Sticky footer
            Divider()
            VStack(spacing: 10) {
                Button {
                    guard let metric = selectedMetric else { return }
                    viewModel.saveActivity(metric: metric, categoryName: selectedCategory, valueText: valueText, note: notes) { success in
                        if success { onSaved() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSavingActivity {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        }
                        Text(viewModel.isSavingActivity ? "Saving…" : "Save Activity")
                    }
                }
                .buttonStyle(HomeActionButtonStyle(isPrimary: true, isDisabled: !canSave))

            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 30, x: 0, y: 8)
        .frame(maxWidth: 390)
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
