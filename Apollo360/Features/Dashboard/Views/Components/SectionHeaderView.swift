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
    let onGridTap: () -> Void

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

//            Button(action: onGridTap) {
//                VStack(spacing: 6) {
//                    HStack(spacing: 6) {
//                        square(color: AppColor.black)
//                        square(color: AppColor.green.opacity(0.8))
//                    }
//                    HStack(spacing: 6) {
//                        square(color: AppColor.green.opacity(0.7))
//                        square(color: AppColor.black.opacity(0.8))
//                    }
//                }
//            }
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

#Preview(traits: .sizeThatFitsLayout) {
    SectionHeaderView(title: "Library", onMenuTap: {}, onGridTap: {})
}
