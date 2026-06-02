import SwiftUI

struct HomePlanCard: View {
    let plan: DashboardPlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(plan.planItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Plan" : plan.planItem)
                .font(AppFont.body(size: 19, weight: .semibold))
                .foregroundColor(AppColor.black)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(authorName)
                    .font(AppFont.body(size: 11, weight: .medium))
                    .foregroundColor(AppColor.black.opacity(0.78))
                Text("• \(daysAgoText)")
                    .font(AppFont.body(size: 11, weight: .regular))
                    .foregroundColor(AppColor.grey)
                Spacer()
            }

            if !plan.patientMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(plan.patientMessage)
                    .font(AppFont.body(size: 13, weight: .regular))
                    .foregroundColor(AppColor.color414141)
            }

            if let first = plan.relatedContent.first {
                VStack(alignment: .leading, spacing: 4) {
                    if let viewingTime = first.viewingTime?.trimmingCharacters(in: .whitespacesAndNewlines), !viewingTime.isEmpty {
                        Text("\(viewingTime) mins read")
                            .font(AppFont.body(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 5).fill(AppColor.green))
                    }
                    Text(first.title)
                        .font(AppFont.body(size: 12, weight: .medium))
                        .foregroundColor(AppColor.black.opacity(0.85))
                        .lineLimit(2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.95)))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColor.green.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 4)
    }

    private var authorName: String {
        let value = plan.author?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "Unknown Author" : value
    }

    private var daysAgoText: String {
        let value = plan.daysAgo.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "0 days ago" : "\(value) days ago"
    }
}
