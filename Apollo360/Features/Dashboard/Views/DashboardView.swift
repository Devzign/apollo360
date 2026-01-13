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

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
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
                })
                .frame(width: 280)
                .transition(.move(edge: .leading))
            }
            .animation(.easeInOut, value: isSideMenuVisible)
        }
    }
}

#Preview {
    DashboardView(session: SessionManager())
}
