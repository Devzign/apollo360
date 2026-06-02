import SwiftUI

struct HomeTargetDetailCardView: View {
    let lookupCategories: [DashboardLookupCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.green)
                Text("Target Metrics")
                    .font(AppFont.body(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.85))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lookupCategories) { category in
                        let accent = categoryAccent(category.category)
                        HStack(spacing: 6) {
                            Image(systemName: categoryIcon(category.category))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(accent)
                            Text("\(category.category) (\(category.metrics.count))")
                                .font(AppFont.body(size: 12, weight: .semibold))
                                .foregroundColor(AppColor.color414141)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accent.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        )
    }

    private func categoryAccent(_ category: String) -> Color {
        switch category.lowercased() {
        case "nutrition": return Color(red: 0.22, green: 0.68, blue: 0.42)
        case "behavior": return Color(red: 0.38, green: 0.50, blue: 0.88)
        case "fitness": return Color(red: 0.92, green: 0.52, blue: 0.18)
        default: return AppColor.green
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "nutrition": return "fork.knife"
        case "behavior": return "brain.head.profile"
        case "fitness": return "figure.run"
        default: return "bolt.fill"
        }
    }
}
