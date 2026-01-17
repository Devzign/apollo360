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
    @State private var bottomSafeArea: CGFloat = 0

    // MARK: - Init
    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(session: session))
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                // Main content
                contentView
                    .background(Color.black.opacity(0.02))
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

                // Tab Bar
                DashboardTabBar(
                    selectedTab: $selectedTab,
                    bottomInset: bottomSafeArea
                )
                .padding(.horizontal, 5)
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(sideMenuOverlay)
            .alert("Logout", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    viewModel.logout()
                }
            } message: {
                Text("Are you sure you want to log out of Apollo360?")
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: BottomSafeAreaPreferenceKey.self,
                    value: proxy.safeAreaInsets.bottom
                )
            }
        )
        .onPreferenceChange(BottomSafeAreaPreferenceKey.self) {
            bottomSafeArea = $0
        }
    }

    // MARK: - Content
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

                    ApolloInsightsCard(insights: viewModel.insights)
                    CardiometabolicMetricsCard(metrics: viewModel.cardioMetrics)

                    ActivitiesSummaryCard(
                        days: viewModel.activityDays,
                        stats: viewModel.activityStats,
                        summaryNote: viewModel.activitySummaryNote,
                        weeklyChangePercent: viewModel.weeklyChangePercent
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }

        default:
            DashboardTabPlaceholderView(
                title: selectedTab.displayTitle
            )
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
}

// MARK: - Safe Area Preference
private struct BottomSafeAreaPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview {
    DashboardView(session: SessionManager())
}
