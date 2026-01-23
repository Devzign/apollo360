//
//  FormsView.swift
//  Apollo360
//
//  Created by Codex on 11/01/26.
//

import SwiftUI

struct FormsView: View {
    private let formTitles: [String] = [
        "Terms, Conditions and Consent",
        "Privacy",
        "Appeal Letter: Medicare Under Review",
        "Credit Card Authorization",
        "Privacy",
        "Appeal Letter: Benefits",
        "Assignment of Benefits and Release"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Apollo 360 Health Forms")
                        .font(AppFont.display(size: 28, weight: .semibold))
                        .foregroundStyle(AppColor.green)

                    Text("Please take a moment to carefully read and sign our patient forms.")
                        .font(AppFont.body(size: 16))
                        .foregroundStyle(AppColor.black.opacity(0.78))
                }

                VStack(spacing: 16) {
                    ForEach(formTitles, id: \.self) { title in
                        FormRow(title: title)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(AppColor.secondary.ignoresSafeArea())
    }
}

private struct FormRow: View {
    let title: String

    var body: some View {
        Button(action: {}) {
            HStack {
                Text(title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.black)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.black.opacity(0.6))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FormsView()
        .previewLayout(.sizeThatFits)
}
