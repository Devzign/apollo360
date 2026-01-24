//
//  SideMenuView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct SideMenuOption: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tab: DashboardTab?
    let badge: Int?
}

struct SideMenuView: View {
    let selectedTab: DashboardTab
    let onSelectTab: (DashboardTab) -> Void
    let onClose: () -> Void
    let logoutAction: () -> Void

    private let options: [SideMenuOption] = [
        SideMenuOption(title: "Dashboard", icon: "square.grid.2x2", tab: .home, badge: nil),
        SideMenuOption(title: "Home", icon: "house", tab: .home, badge: nil),
        SideMenuOption(title: "Messages", icon: "bubble.left.and.bubble.right", tab: .message, badge: 3),
        SideMenuOption(title: "Library", icon: "books.vertical", tab: .library, badge: nil),
        SideMenuOption(title: "Metrics", icon: "waveform.path.ecg", tab: .metrics, badge: nil),
        SideMenuOption(title: "Forms", icon: "waveform.path.ecg.text.clipboard", tab: .forms, badge: nil),
        SideMenuOption(title: "Assessments", icon: "doc.text.magnifyingglass", tab: .metrics, badge: 2),
        SideMenuOption(title: "Records", icon: "folder", tab: nil, badge: nil),
        SideMenuOption(title: "Appointments", icon: "calendar.badge.clock", tab: .appointment, badge: nil),
        SideMenuOption(title: "Settings", icon: "gearshape", tab: nil, badge: nil)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColor.green, AppColor.green.opacity(0.90)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(options) { option in
                            menuRow(for: option)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                Spacer()

                Divider()
                    .background(Color.white.opacity(0.4))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                logoutRow
                    .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundStyle(.white)
                .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text("Hello,")
                    .font(AppFont.body(size: 16))
                    .foregroundStyle(.white.opacity(0.85))
                Text("John Marks")
                    .font(AppFont.display(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2))
            }
            .padding(.trailing, 12)
        }
        .padding(.top, 48)
    }

    private func menuRow(for option: SideMenuOption) -> some View {
        let isActive = option.tab == selectedTab

        return Button {
            if let tab = option.tab {
                onSelectTab(tab)
            }
            onClose()
        } label: {
            HStack {
                Image(systemName: option.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28)
                Text(option.title)
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if let badge = option.badge {
                    Text("\(badge)")
                        .font(AppFont.body(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                }
                if isActive {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isActive ? 0.18 : 0))
            )
        }
        .buttonStyle(.plain)
    }

    private var logoutRow: some View {
        Button(action: {
            logoutAction()
            onClose()
        }) {
            HStack(spacing: 14) {
                Image(systemName: "arrow.backward.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                Text("Logout")
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Side Menu") {
    SideMenuView(
        selectedTab: .home,
        onSelectTab: { _ in },
        onClose: {},
        logoutAction: {}
    )
    .frame(width: 320)
}
