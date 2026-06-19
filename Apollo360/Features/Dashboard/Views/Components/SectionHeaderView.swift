//
//  SectionHeaderView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let isSyncing: Bool
    var avatarText: String? = nil
    let onMenuTap: () -> Void
    let onSyncTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onMenuTap) {
                ZStack {
                    Circle()
                        .fill(Color(red: 235 / 255, green: 247 / 255, blue: 240 / 255))
                        .frame(width: 42, height: 42)
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 35 / 255, green: 59 / 255, blue: 55 / 255))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(AppFont.display(size: 20, weight: .bold))
                .foregroundColor(AppColor.black)

            Spacer()
            if title == "Dashboard" {
                Button(action: onSettingsTap) {
                    Text(avatarText ?? "AU")
                        .font(AppFont.body(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(red: 0 / 255, green: 153 / 255, blue: 102 / 255)))
                        .overlay(Circle().stroke(Color(red: 221 / 255, green: 246 / 255, blue: 233 / 255), lineWidth: 6))
                }
                .buttonStyle(.plain)
                .frame(width: 42, height: 42)
            } else {
                Button(action: onSyncTap) {
                    HeaderIconButton(systemImage: "arrow.triangle.2.circlepath", showsBadge: false, isSpinning: isSyncing)
                }
                .disabled(isSyncing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(title == "Dashboard" ? Color(red: 246 / 255, green: 255 / 255, blue: 249 / 255) : AppColor.secondary)
        .overlay(alignment: .bottom) {
            if title == "Dashboard" {
                Rectangle()
                    .fill(Color(red: 226 / 255, green: 239 / 255, blue: 232 / 255))
                    .frame(height: 1)
            }
        }
    }

    private func square(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color)
            .frame(width: 20, height: 20)
    }
}

private struct HeaderIconButton: View {
    let systemImage: String
    let showsBadge: Bool
    let isSpinning: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.colorECF0F3)
                .frame(width: 40, height: 40)
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(AppColor.black)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(isSpinning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSpinning)
            if showsBadge {
                Circle()
                    .fill(AppColor.red)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(AppColor.secondary, lineWidth: 2)
                    )
                    .offset(x: 12, y: -12)
            }
        }
        .frame(width: 40, height: 40)
    }
}

#if DEBUG
struct SectionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeaderView(title: "Library", isSyncing: false, onMenuTap: {}, onSyncTap: {}, onSettingsTap: {})
            .previewLayout(.sizeThatFits)
    }
}
#endif
