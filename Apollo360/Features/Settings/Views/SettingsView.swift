//
//  SettingsView.swift
//  Apollo360
//
//  Created by Amit Sinha on 31/01/26.
//

import SwiftUI

struct SettingsView: View {
    let horizontalPadding: CGFloat
    private let session: SessionManager
    @StateObject private var viewModel: SettingsViewModel
    @State private var isShowingLogoutConfirmation = false

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        self.session = session
        _viewModel = StateObject(wrappedValue: SettingsViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                VStack(spacing: 28) {
                    ForEach(viewModel.sections) { section in
                        sectionView(for: section)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(AppColor.secondary.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Apollo 360 Settings")
                .font(AppFont.display(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.green)

            Text("Customize your experience, manage privacy, and review important agreements.")
                .font(AppFont.body(size: 16))
                .foregroundStyle(AppColor.black.opacity(0.78))
        }
    }

    @ViewBuilder
    private func sectionView(for section: SettingSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = section.title {
                Text(title)
                    .font(AppFont.body(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.green)
                    .textCase(.uppercase)
            }
            VStack(spacing: 16) {
                ForEach(section.items) { item in
                    if case .logout = item.kind {
                        Button {
                            isShowingLogoutConfirmation = true
                        } label: {
                            SettingRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .alert("Log out", isPresented: $isShowingLogoutConfirmation) {
                            Button("Cancel", role: .cancel) {}
                            Button("Logout", role: .destructive) {
                                viewModel.logout()
                            }
                        } message: {
                            Text("Logging out will end your session and require signing in again.")
                        }
                    } else {
                        NavigationLink {
                            destination(for: item)
                        } label: {
                            SettingRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for item: SettingItem) -> some View {
        switch item.kind {
        case .terms, .privacy, .staticItem:
            SettingDetailView(
                item: item,
                htmlContent: viewModel.html(for: item.kind),
                isLoading: viewModel.isLoadingLegal,
                errorMessage: viewModel.errorMessage,
                reload: viewModel.refreshLegal
            )
        case .forms:
            FormsView(horizontalPadding: horizontalPadding, session: session)
        case .contact:
            ContactUsView()
        case .creditCard:
            CreditCardView(session: session)
        case .notifications:
            NotificationsView()
        case .caregivers:
            CaregiversView(session: session)
        case .team:
            SettingDetailView(
                item: item,
                htmlContent: viewModel.html(for: item.kind),
                isLoading: viewModel.isLoadingTeam,
                errorMessage: viewModel.errorMessage,
                reload: viewModel.refreshTeam
            )
        case .billing:
            BillingView(session: session)
        case .profile:
            UserProfileView(session: session)
        case .logout:
            LogoutView(logoutAction: viewModel.logout)
        }
    }
}

#Preview("Settings - iPhone", traits: .sizeThatFitsLayout) {
    NavigationStack {
        SettingsView(horizontalPadding: 20, session: SessionManager())
            .environment(\.horizontalSizeClass, .compact)
    }
    .toolbar(.hidden, for: .tabBar)
}

#Preview("Settings - iPad", traits: .sizeThatFitsLayout) {
    NavigationStack {
        SettingsView(horizontalPadding: 50, session: SessionManager())
            .environment(\.horizontalSizeClass, .regular)
    }
    .toolbar(.hidden, for: .tabBar)
}
