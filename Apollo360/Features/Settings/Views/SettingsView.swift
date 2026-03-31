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
    @State private var selectedItem: SettingItem?

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
                .foregroundColor(AppColor.green)

            Text("Customize your experience, manage privacy, and review important agreements.")
                .font(AppFont.body(size: 16))
                .foregroundColor(AppColor.black.opacity(0.78))
        }
    }

    @ViewBuilder
    private func sectionView(for section: SettingSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = section.title {
                Text(title)
                    .font(AppFont.body(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.green)
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
                    } else {
                        Button {
                            selectedItem = item
                        } label: {
                            SettingRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .background(
            NavigationLink(
                destination: selectedDestination,
                isActive: Binding(
                    get: { selectedItem != nil },
                    set: { if !$0 { selectedItem = nil } }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        .alert(isPresented: $isShowingLogoutConfirmation) {
            Alert(
                title: Text("Log out"),
                message: Text("Logging out will end your session and require signing in again."),
                primaryButton: .destructive(Text("Logout")) {
                    viewModel.logout()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var selectedDestination: AnyView {
        guard let item = selectedItem else {
            return AnyView(EmptyView())
        }
        return destination(for: item)
    }

    private func destination(for item: SettingItem) -> AnyView {
        switch item.kind {
        case .terms, .privacy, .staticItem:
            return AnyView(SettingDetailView(
                item: item,
                htmlContent: viewModel.html(for: item.kind),
                isLoading: viewModel.isLoadingLegal,
                errorMessage: viewModel.errorMessage,
                reload: viewModel.refreshLegal
            ))
        case .forms:
            return AnyView(FormsView(horizontalPadding: horizontalPadding, session: session))
        case .contact:
            return AnyView(ContactUsView())
        case .creditCard:
            return AnyView(CreditCardView(session: session))
        case .notifications:
            return AnyView(NotificationsView(session: session))
        case .caregivers:
            return AnyView(CaregiversView(session: session))
        case .team:
            return AnyView(SettingDetailView(
                item: item,
                htmlContent: viewModel.html(for: item.kind),
                isLoading: viewModel.isLoadingTeam,
                errorMessage: viewModel.errorMessage,
                reload: viewModel.refreshTeam
            ))
        case .billing:
            return AnyView(BillingView(session: session))
        case .profile:
            return AnyView(UserProfileView(session: session))
        case .logout:
            return AnyView(LogoutView(logoutAction: viewModel.logout))
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SettingsView(horizontalPadding: 20, session: SessionManager())
                    .environment(\.horizontalSizeClass, .compact)
            }
            .previewDisplayName("Settings - iPhone")

            NavigationView {
                SettingsView(horizontalPadding: 50, session: SessionManager())
                    .environment(\.horizontalSizeClass, .regular)
            }
            .previewDisplayName("Settings - iPad")
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
