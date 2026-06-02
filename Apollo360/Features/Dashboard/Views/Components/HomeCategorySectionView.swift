import SwiftUI

struct HomeCategorySectionView: View {
    let title: String
    let plans: [DashboardPlanItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 17))
                    .foregroundColor(AppColor.green)
                Text(title)
                    .font(AppFont.display(size: 17, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.85))
            }

            if plans.isEmpty {
                Text("No plans available.")
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.grey)
                    .padding(.vertical, 4)
            } else {
                ForEach(plans) { plan in
                    HomePlanCard(plan: plan)
                }
            }
        }
    }
}
