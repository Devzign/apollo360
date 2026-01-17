//
//  DashboardTabPlaceholderView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

extension DashboardTab {
    var displayTitle: String {
        switch self {
        case .metrics:
            return "Metrics"
        case .library:
            return "Library"
        case .home:
            return "Home"
        case .message:
            return "Messages"
        case .appointment:
            return "Appointments"
        }
    }
}


struct DashboardTabPlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(title)
                .font(AppFont.display(size: 28, weight: .bold))
                .foregroundStyle(AppColor.black)
            Text("Content coming soon.")
                .font(AppFont.body(size: 16))
                .foregroundStyle(AppColor.grey)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
