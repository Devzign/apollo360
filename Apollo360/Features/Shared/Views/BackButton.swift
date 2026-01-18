//
//  BackButton.swift
//  Apollo360
//
//  Created by Codex on 11/01/26.
//

import SwiftUI

struct BackButton: View {
    let label: String?
    let action: () -> Void

    init(label: String? = nil, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                if let label {
                    Text(label)
                        .font(AppFont.body(size: 16, weight: .medium))
                }
            }
            .foregroundStyle(AppColor.black)
            .padding(10)
            .background(
                Circle()
                    .fill(AppColor.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
struct BackButton_Previews: PreviewProvider {
    static var previews: some View {
        BackButton(label: "Back") {}
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
