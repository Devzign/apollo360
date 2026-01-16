//
//  DashboardView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedTab: DashboardTab = .home
    @State private var isSideMenuVisible: Bool = false
    private let session: SessionManager
    @State private var showingLogoutConfirmation = false

    init(session: SessionManager) {
        self.session = session
        _viewModel = StateObject(wrappedValue: DashboardViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                contentView
                    .background(Color.black.opacity(0.02))

                VStack(spacing: 0) {
                    DashboardTabBar(selectedTab: $selectedTab)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)
            }
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
            .toolbar(.hidden, for: .navigationBar)
            .overlay(sideMenuOverlay)
            .alert("Logout", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) {
                    showingLogoutConfirmation = false
                }
                Button("Logout", role: .destructive) {
                    showingLogoutConfirmation = false
                    handleLogout()
                }
            } message: {
                Text("Are you sure you want to log out of Apollo360?")
            }
        }
    }

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
                    .dashboardSlideUp(delay: 0.3)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        default:
            DashboardTabPlaceholderView(title: selectedTab.displayTitle)
        }
    }

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

                SideMenuView(onClose: {
                    withAnimation(.easeInOut) {
                        isSideMenuVisible = false
                    }
                }, logoutAction: {
                    showingLogoutConfirmation = true
                })
                .frame(width: 280)
                .transition(.move(edge: .leading))
            }
            .animation(.easeInOut, value: isSideMenuVisible)
        }
    }

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

#Preview {
    DashboardView(session: SessionManager())
}
