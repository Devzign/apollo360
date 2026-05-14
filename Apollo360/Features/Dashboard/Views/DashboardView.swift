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
    @State private var selectedTab: DashboardTab = .dashboard
    @State private var isSideMenuVisible = false
    @State private var showingLogoutConfirmation = false
    @State private var isSyncDevicesVisible = false
    @State private var bottomSafeArea: CGFloat = 0
    private let session: SessionManager
    private var screenHorizontalPadding: CGFloat { isiPad() ? 100 : 20 }
    private var headerHorizontalPadding: CGFloat { isiPad() ? screenHorizontalPadding : 0 }
    
    // MARK: - Init
    init(session: SessionManager) {
        self.session = session
        _viewModel = StateObject(wrappedValue: DashboardViewModel(session: session))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    SectionHeaderView(
                        title: selectedTab.displayTitle,
                        isSyncing: viewModel.isHeaderSyncing,
                        onMenuTap: {
                            isSideMenuVisible = true
                        },
                        onSyncTap: {
                            isSyncDevicesVisible = true
                        },
                        onSettingsTap: {
                            selectedTab = .settings
                        }
                    )
                    .padding(.horizontal, headerHorizontalPadding)
                    contentView
                        .background(Color.black.opacity(0.02))
                }

                if selectedTab != .settings {
                    DashboardTabBar(
                        selectedTab: $selectedTab,
                        bottomInset: bottomSafeArea
                    )
                    .padding(.horizontal, 5)
                }
            }
            .navigationBarHidden(true)
            .overlay(
                ZStack {
                    if viewModel.isLoading {
                        AppShimmerOverlay()
                    }
                    sideMenuOverlay
                }
            )
            .alert(isPresented: $showingLogoutConfirmation) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to log out of Apollo360?"),
                    primaryButton: .destructive(Text("Logout")) {
                        viewModel.logout()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Sync Failed", isPresented: Binding(
                get: { viewModel.syncErrorMessage != nil },
                set: { if !$0 { viewModel.syncErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.syncErrorMessage = nil
                }
            } message: {
                Text(viewModel.syncErrorMessage ?? "")
            }
            .background(
                NavigationLink(
                    destination: DeviceSyncView(session: session),
                    isActive: $isSyncDevicesVisible
                ) {
                    EmptyView()
                }
                .hidden()
            )
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
        case .dashboard:
//            ScrollView {
//                VStack(spacing: 24) {
//                    StoriesSectionView(
//                        title: viewModel.snapshotTitle,
//                        subtitle: viewModel.snapshotSubtitle,
//                        stories: viewModel.stories
//                    )
//
//                    WellnessSectionView(
//                        title: viewModel.wellnessTitle,
//                        description: viewModel.wellnessDescription,
//                        currentScore: viewModel.currentScore,
//                        previousScore: viewModel.previousScore,
//                        progress: viewModel.progress,
//                        metrics: viewModel.wellnessMetrics,
//                        isImproving: viewModel.isWellnessImproving,
//                        changeValue: viewModel.wellnessChange,
//                        mode: $viewModel.wellnessMode
//                    )
//
//                    InsightsSectionView(insights: viewModel.insights)
//
//                    CardioSectionView(metrics: viewModel.cardioMetrics)
//
//                    ActivitiesSectionView(
//                        days: viewModel.activityDays,
//                        stats: viewModel.activityStats,
//                        summaryNote: viewModel.activitySummaryNote,
//                        weeklyChangePercent: viewModel.weeklyChangePercent
//                    )
//
//                    Color.clear
//                        .frame(height: bottomSafeArea + 180)
//                }
//                .padding(.horizontal, screenHorizontalPadding)
//                .padding(.top, 16)
//            }

            DoctorMeDashboard(
                doctorMetrics: viewModel.doctorMetricCards,
                myMetrics: viewModel.myMetricCards,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.homeMetricsError,
                session: session,
                onSelectMetrics: {
                    selectedTab = .metrics
                }
            )
        case .home:
            HomeNew(session: session)
        case .metrics:
            MetricsView(horizontalPadding: screenHorizontalPadding, session: session)

        case .library:
            LibraryView(horizontalPadding: screenHorizontalPadding, session: session)

        case .forms:
            FormsView(horizontalPadding: screenHorizontalPadding, session: session)

        case .assessments:
            AssessmentsView(horizontalPadding: screenHorizontalPadding, session: session)

        case .records:
            RecordsView(horizontalPadding: screenHorizontalPadding, session: session)

        case .appointment:
            AppointmentView(horizontalPadding: screenHorizontalPadding, session: session)

        case .message:
            MessageListView(session: session)
                .padding(.horizontal, screenHorizontalPadding / 2)

        case .settings:
            SettingsView(horizontalPadding: screenHorizontalPadding, session: session)
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
                        closeSideMenu()
                    }

                    SideMenuView(
                        selectedTab: selectedTab,
                        userDisplayName: viewModel.userName,
                        onSelectTab: { selectedTab = $0 },
                        onClose: closeSideMenu,
                        logoutAction: {
                            showingLogoutConfirmation = true
                        }
                    )
                .frame(width: 280)
                .modifier(SideMenuMotion(isVisible: isSideMenuVisible))
            }
        }
    }

    private func closeSideMenu() {
        isSideMenuVisible = false
    }
}
// MARK: - Safe Area Preference
private struct BottomSafeAreaPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension AnyTransition {
    static var sideMenu: AnyTransition {
        let insertion = AnyTransition.move(edge: .leading)
            .combined(with: .scale(scale: 0.95, anchor: .leading))
            .combined(with: .opacity)
        let removal = AnyTransition.move(edge: .leading)
            .combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

private struct SideMenuMotion: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.92, anchor: .leading)
            .rotation3DEffect(
                .degrees(isVisible ? 0 : -12),
                axis: (x: 0, y: 1, z: 0),
                anchor: .leading,
                perspective: 0.7
            )
            .shadow(color: Color.black.opacity(0.4), radius: 30, y: 18)
    }
}

// MARK: - Preview
#Preview {
    DashboardView(session: SessionManager())
}
