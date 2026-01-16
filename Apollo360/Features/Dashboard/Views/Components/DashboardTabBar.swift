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

    private let leadingItems: [DashboardTab] = [.metrics, .library]
    private let trailingItems: [DashboardTab] = [.message, .appointment]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 8)

            HStack {
                HStack(spacing: 24) {
                    ForEach(leadingItems, id: \.self) { tab in
                        tabButton(for: tab)
                    }
                }
                Spacer()
                HStack(spacing: 24) {
                    ForEach(trailingItems, id: \.self) { tab in
                        tabButton(for: tab)
                    }
                }
            }
            .padding(.horizontal, 32)

            Button(action: {
                selectedTab = .home
            }) {
                ZStack {
                    Circle()
                        .fill(AppColor.green)
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 74, height: 74)
                    Image(systemName: "house.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -30)
        }
        .frame(height: 80)
    }

    @ViewBuilder
    private func tabButton(for tab: DashboardTab) -> some View {
        let info = tabInfo(for: tab)
        Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: info.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? AppColor.green : AppColor.black)
                Text(info.title)
                    .font(AppFont.body(size: 12, weight: .semibold))
                    .foregroundStyle(selectedTab == tab ? AppColor.green : AppColor.black)
            }
        }
        .buttonStyle(.plain)
    }

    private func tabInfo(for tab: DashboardTab) -> (icon: String, title: String) {
        switch tab {
        case .metrics:
            return ("chart.line.uptrend.xyaxis", "Metrics")
        case .library:
            return ("books.vertical", "Library")
        case .message:
            return ("bubble.left.and.bubble.right", "Message")
        case .appointment:
            return ("calendar.badge.clock", "Appoint.")
        default:
            return ("house.fill", "Home")
        }
    }
}

extension DashboardTab {
    var displayTitle: String {
        switch self {
        case .metrics: return "Metrics"
        case .library: return "Library"
        case .home: return "Home"
        case .message: return "Messages"
        case .appointment: return "Appointments"
        }
    }
}
