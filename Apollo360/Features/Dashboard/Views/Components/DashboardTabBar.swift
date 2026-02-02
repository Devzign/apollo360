//
//  DashboardTabBar.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

enum DashboardTab: String, CaseIterable {
    case metrics
    case library
    case home
    case message
    case appointment
    case forms
    case settings
}

struct DashboardTabBar: View {

    @Binding var selectedTab: DashboardTab
    var bottomInset: CGFloat = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Constants
    private let leadingItems: [DashboardTab] = [.metrics, .library]
    private let trailingItems: [DashboardTab] = [.message, .appointment]
    private let cornerRadius: CGFloat = 32
    private let inactiveTint = Color(red: 65 / 255, green: 65 / 255, blue: 65 / 255)

    private var barHeight: CGFloat {
        horizontalSizeClass == .regular ? 85 : 78
    }

    private var barMaxWidth: CGFloat? {
        horizontalSizeClass == .regular ? 550 : nil
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 32 : 6
    }

    private var itemSpacing: CGFloat {
        horizontalSizeClass == .regular ? 40 : 20
    }

    private var tabGroupPadding: CGFloat {
        isiPad() ? 40 : 16
    }

    private var iconSize: CGFloat {
        horizontalSizeClass == .regular ? 30 : 24
    }

    private var centerButtonDiameter: CGFloat {
        horizontalSizeClass == .regular ? 76 : 68
    }

    private var bottomPadding: CGFloat {
        if horizontalSizeClass == .regular {
            return max(bottomInset, 12)
        }
        return max(bottomInset - 28, 0)
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: -6)

                    HStack {
                        tabGroup(items: leadingItems)

                        Spacer()

                        tabGroup(items: trailingItems)
                    }
                    .padding(.horizontal, tabGroupPadding)
                    .padding(.top, 14)
                }
                .frame(height: barHeight)
                .frame(maxWidth: barMaxWidth)
                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, bottomPadding)

            centerButton
                .offset(y: -barHeight * 0.42)
        }
        .frame(height: barHeight + centerButtonDiameter * 0.65 + bottomPadding)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Center Button
    private var centerButton: some View {
        Button {
            selectedTab = .home
        } label: {
            let isActive = selectedTab == .home
            let circleColor = isActive ? AppColor.green : inactiveTint

            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 5)
                    .frame(width: centerButtonDiameter + 16, height: centerButtonDiameter + 16)

                Circle()
                    .stroke(Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255), lineWidth: 4)
                    .frame(width: centerButtonDiameter + 8, height: centerButtonDiameter + 8)

                Circle()
                    .fill(circleColor)
                    .frame(width: centerButtonDiameter, height: centerButtonDiameter)
                    .shadow(color: Color.black.opacity(0.18), radius: 10, y: 6)

                Image("home")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize + 4, height: iconSize + 4)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Group
    private func tabGroup(items: [DashboardTab]) -> some View {
        HStack(spacing: itemSpacing) {
            ForEach(items, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
    }

    // MARK: - Tab Button
    private func tabButton(for tab: DashboardTab) -> some View {
        let info = tabInfo(for: tab)
        let isSelected = selectedTab == tab
        let tint = isSelected ? AppColor.green : inactiveTint

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(info.asset)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(tint)

                Text(info.title)
                    .font(AppFont.body(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Info
    private func tabInfo(for tab: DashboardTab) -> (asset: String, title: String) {
        switch tab {
        case .metrics:
            return ("metrics", "Metrics")
        case .library:
            return ("library", "Library")
        case .message:
            return ("message", "Message")
        case .appointment:
            return ("appoinment", "Appoint.")
        case .home:
            return ("home", "Home")
        case .forms:
            return ("metrics", "Forms")
        case .settings:
            return ("library", "Settings")
        }
    }
}

#Preview {
    DashboardTabBar(
        selectedTab: .constant(.home),
        bottomInset: 34
    )
}
