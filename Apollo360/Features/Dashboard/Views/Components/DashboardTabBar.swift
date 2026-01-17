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

            Color.white
                .ignoresSafeArea(.container, edges: .bottom)
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: -10)

            TopRoundedRectangle(cornerRadius: 32)
                .fill(Color.white)

            HStack {
                HStack(spacing: 20) {
                    ForEach(leadingItems, id: \.self) { tab in
                        tabButton(for: tab)
                    }
                }

                Spacer()

                HStack(spacing: 20) {
                    ForEach(trailingItems, id: \.self) { tab in
                        tabButton(for: tab)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Button {
                selectedTab = .home
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 85, height: 85)
                        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)

                    Circle()
                        .stroke(AppColor.green.opacity(0.35), lineWidth: 6)
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(AppColor.green)
                        .frame(width: 60, height: 60)

                    Image(systemName: "house.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -28)
        }
        .frame(height: 80)
    }

    // MARK: - Tab Button
    @ViewBuilder
    private func tabButton(for tab: DashboardTab) -> some View {
        let info = tabInfo(for: tab)

        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: info.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        selectedTab == tab ? AppColor.green : AppColor.black
                    )

                Text(info.title)
                    .font(AppFont.body(size: 12, weight: .semibold))
                    .foregroundStyle(
                        selectedTab == tab ? AppColor.green : AppColor.black
                    )
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
#Preview { DashboardTabBar(selectedTab: .constant(.home)) .padding() }
