import SwiftUI

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
                    HomeGoalCardView(
                        greeting: viewModel.greeting,
                        fullName: viewModel.fullName,
                        mainGoal: viewModel.mainGoal,
                        pendingAssessments: viewModel.pendingAssessments,
                        onFeelingTap: { withAnimation { isFeelingOpen = true } },
                        onActivitiesTap: { withAnimation { isActivitiesOpen = true } }
                    )

                    HomeSectionSwitcherView(selection: $homeSection)

                    switch homeSection {
                    case .plans:
                        HomeTargetDetailCardView(lookupCategories: viewModel.lookupCategories)
                        HomeCategorySectionView(title: "Nutrition", plans: viewModel.nutritionPlans)
                        HomeCategorySectionView(title: "Behavior", plans: viewModel.behaviorPlans)
                        HomeCategorySectionView(title: "Fitness", plans: viewModel.fitnessPlans)
                    case .feeling:
                        HomeFeelingSectionView(
                            recentSymptoms: viewModel.recentSymptoms,
                            onLogTap: { withAnimation { isFeelingOpen = true } }
                        )
                    case .activities:
                        HomeActivitiesSectionView(
                            gauges: viewModel.gauges,
                            submittedActivities: viewModel.submittedActivities,
                            onLogTap: { withAnimation { isActivitiesOpen = true } }
                        )
                    }

                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.96, blue: 0.95), Color(red: 0.93, green: 0.95, blue: 0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )

            if viewModel.isLoading &&
                viewModel.nutritionPlans.isEmpty &&
                viewModel.behaviorPlans.isEmpty &&
                viewModel.fitnessPlans.isEmpty {
                ProgressView("Loading Home...")
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            }
        }
        .refreshable { viewModel.load() }
        .sheet(isPresented: $isFeelingOpen) {
            NavigationView {
                FeelingSheet(
                    viewModel: viewModel,
                    onSaved: {
                        isFeelingOpen = false
                        withAnimation(.easeInOut(duration: 0.25)) { homeSection = .feeling }
                    },
                    onCancel: { isFeelingOpen = false }
                )
            }
            .navigationViewStyle(.stack)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .modifier(PresentationCornerRadiusModifier(radius: 26))
        }
        .sheet(isPresented: $isActivitiesOpen) {
            NavigationView {
                ActivitiesSheet(
                    viewModel: viewModel,
                    onSaved: {
                        isActivitiesOpen = false
                        withAnimation(.easeInOut(duration: 0.25)) { homeSection = .activities }
                    },
                    onCancel: { isActivitiesOpen = false }
                )
            }
            .navigationViewStyle(.stack)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .modifier(PresentationCornerRadiusModifier(radius: 26))
        }
    }
}
