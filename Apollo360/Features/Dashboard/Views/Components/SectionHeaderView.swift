//
//  SectionHeaderView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let onMenuTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onMenuTap) {
                VStack(spacing: 6) {
                    Capsule()
                        .fill(AppColor.green)
                        .frame(width: 28, height: 6)
                    Capsule()
                        .fill(AppColor.black.opacity(0.7))
                        .frame(width: 34, height: 6)
                    Capsule()
                        .fill(AppColor.green)
                        .frame(width: 20, height: 6)
                }
            }

            Spacer()

            Text(title)
                .font(AppFont.display(size: 22, weight: .bold))
                .foregroundStyle(AppColor.black)

            Spacer()

            Button(action: onSettingsTap) {
                HeaderIconButton(systemImage: "gearshape.fill", showsBadge: false)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColor.secondary)
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

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.colorECF0F3)
                .frame(width: 40, height: 40)
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppColor.black)
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

#Preview(traits: .sizeThatFitsLayout) {
    SectionHeaderView(title: "Library", onMenuTap: {}, onSettingsTap: {})
}
