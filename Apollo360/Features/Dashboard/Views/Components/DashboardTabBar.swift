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
}

struct DashboardTabBar: View {

    @Binding var selectedTab: DashboardTab
    var bottomInset: CGFloat = 0

    // MARK: - Constants
    private let leadingItems: [DashboardTab] = [.metrics, .library]
    private let trailingItems: [DashboardTab] = [.message, .appointment]
    private let cornerRadius: CGFloat = 34
    private let barHeight: CGFloat = 88
    private let inactiveTint = Color(red: 65 / 255, green: 65 / 255, blue: 65 / 255)

    // MARK: - Body
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: -8)

            // Tabs
            HStack {
                tabGroup(items: leadingItems)

                Spacer()

                tabGroup(items: trailingItems)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
        }
        .frame(height: barHeight + bottomInset)
        .overlay(centerButton.offset(y: -barHeight * 0.4))
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
                    .stroke(Color.white, lineWidth: 6)
                    .frame(width: 98, height: 98)

                Circle()
                    .stroke(Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255), lineWidth: 5)
                    .frame(width: 86, height: 86)

                Circle()
                    .fill(circleColor)
                    .frame(width: 74, height: 74)

                Image("home")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Group
    private func tabGroup(items: [DashboardTab]) -> some View {
        HStack(spacing: 34) {
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
                    .frame(width: 28, height: 28)
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
            return ("matrics", "Metrics")
        case .library:
            return ("library", "Library")
        case .message:
            return ("message", "Message")
        case .appointment:
            return ("appoinment", "Appoint.")
        case .home:
            return ("home", "Home")
        }
    }
}

#Preview {
    DashboardTabBar(
        selectedTab: .constant(.home),
        bottomInset: 34
    )
}
