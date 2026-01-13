//
//  SideMenuView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct SideMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let badge: Int?
}

struct SideMenuView: View {
    let onClose: () -> Void

    private let menuItems: [SideMenuItem] = [
        SideMenuItem(title: "Dashboard", icon: "square.grid.2x2", badge: nil),
        SideMenuItem(title: "Home", icon: "house", badge: nil),
        SideMenuItem(title: "Messages", icon: "message", badge: 3),
        SideMenuItem(title: "Library", icon: "books.vertical", badge: nil),
        SideMenuItem(title: "RPM Metrics", icon: "waveform.path.ecg", badge: nil),
        SideMenuItem(title: "LAB Metrics", icon: "lab.flask", badge: nil),
        SideMenuItem(title: "Assessments", icon: "doc.text.magnifyingglass", badge: 2),
        SideMenuItem(title: "Records", icon: "folder", badge: nil),
        SideMenuItem(title: "Appointments", icon: "calendar.badge.clock", badge: nil),
        SideMenuItem(title: "Settings", icon: "gearshape", badge: nil),
    ]

    var body: some View {
        ZStack(alignment: .leading) {
            AppColor.green
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AppColor.green)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hello,")
                            .font(AppFont.body(size: 16, weight: .regular))
                            .foregroundStyle(.white)
                        Text("John Marks")
                            .font(AppFont.body(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().stroke(.white.opacity(0.7), lineWidth: 1.5))
                    }
                }
                .padding(.top, 32)

                ForEach(menuItems) { item in
                    HStack {
                        Image(systemName: item.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                        Text(item.title)
                            .font(AppFont.body(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        if let badge = item.badge {
                            Text("\(badge)")
                                .font(AppFont.body(size: 12, weight: .bold))
                                .foregroundStyle(AppColor.green)
                                .padding(6)
                                .background(Circle().fill(.white))
                        }
                    }
                }

                Spacer()

                Button(action: {}) {
                    HStack {
                        Image(systemName: "arrow.backward.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Logout")
                            .font(AppFont.body(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
