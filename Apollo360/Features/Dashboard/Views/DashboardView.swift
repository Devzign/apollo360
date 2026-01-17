//
//  DashboardView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct DashboardView: View {

    // MARK: - State
    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedTab: DashboardTab = .home
    @State private var isSideMenuVisible = false
    @State private var showingLogoutConfirmation = false

    private let session: SessionManager

    // MARK: - Init
    init(session: SessionManager) {
        self.session = session
        _viewModel = StateObject(wrappedValue: DashboardViewModel(session: session))
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            contentView
                .background(Color.black.opacity(0.02))

                // ✅ TOP HEADER
                .safeAreaInset(edge: .top, spacing: 0) {
                    DashboardHeaderView(
                        greeting: viewModel.greeting,
                        userName: viewModel.userName,
                        onMenuTap: {
                            withAnimation(.easeInOut) {
                                isSideMenuVisible = true
                            }
                        }
                    )
                }

                // ✅ BOTTOM TAB BAR (CORRECT)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    DashboardTabBar(selectedTab: $selectedTab)
                        .frame(height: 80)
                        .background(
                            Color.white
                                .shadow(color: .black.opacity(0.1), radius: 10, y: -4)
                        )
                }

                .toolbar(.hidden, for: .navigationBar)
                .overlay(sideMenuOverlay)
                .alert("Logout", isPresented: $showingLogoutConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Logout", role: .destructive) {
                        handleLogout()
                    }
                } message: {
                    Text("Are you sure you want to log out of Apollo360?")
                }
        }
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {

        case .home:
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
                    .dashboardSlideUp(delay: 0.30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

        default:
            DashboardTabPlaceholderView(title: selectedTab.displayTitle)
        }
    }

    // MARK: - Side Menu
    @ViewBuilder
    private var sideMenuOverlay: some View {
        if isSideMenuVisible {
            ZStack(alignment: .leading) {

                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isSideMenuVisible = false
                        }
                    }

                SideMenuView(
                    onClose: {
                        withAnimation(.easeInOut) {
                            isSideMenuVisible = false
                        }
                    },
                    logoutAction: {
                        showingLogoutConfirmation = true
                    }
                )
                .frame(width: 280)
                .transition(.move(edge: .leading))
            }
        }
    }

    // MARK: - Logout
    private func handleLogout() {
        withAnimation(.easeInOut) {
            isSideMenuVisible = false
        }

        guard let token = session.accessToken else {
            session.clearSession()
            return
        }

        APIClient.shared.logout(bearerToken: token) { _ in
            session.clearSession()
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView(session: SessionManager())
}
