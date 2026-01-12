import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    DailyStoriesView(
                        title: viewModel.snapshotTitle,
                        subtitle: viewModel.snapshotSubtitle,
                        stories: viewModel.stories
                    )
                    .dashboardSlideUp(delay: 0.05)

                    WellnessScoreCard(
                        title: viewModel.wellnessTitle,
                        description: viewModel.wellnessDescription,
                        currentScore: viewModel.currentScore,
                        previousScore: viewModel.previousScore,
                        progress: viewModel.progress,
                        metrics: viewModel.wellnessMetrics,
                        isImproving: viewModel.isWellnessImproving,
                        changeValue: viewModel.wellnessChange,
                        mode: $viewModel.wellnessMode
                    )
                    .dashboardSlideUp(delay: 0.12)

                    ApolloInsightsCard(insights: viewModel.insights)
                        .dashboardSlideUp(delay: 0.18)
                    CardiometabolicMetricsCard(metrics: viewModel.cardioMetrics)
                        .dashboardSlideUp(delay: 0.24)
                    ActivitiesSummaryCard(
                        days: viewModel.activityDays,
                        stats: viewModel.activityStats,
                        summaryNote: viewModel.activitySummaryNote,
                        weeklyChangePercent: viewModel.weeklyChangePercent
                    )
                    .dashboardSlideUp(delay: 0.3)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.black.opacity(0.02))
            .safeAreaInset(edge: .top, spacing: 0) {
                DashboardHeaderView(
                    greeting: viewModel.greeting,
                    userName: viewModel.userName
                )
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    DashboardView(session: SessionManager())
}
