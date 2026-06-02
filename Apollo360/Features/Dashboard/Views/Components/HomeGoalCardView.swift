import SwiftUI

struct HomeGoalCardView: View {
    let greeting: String
    let fullName: String
    let mainGoal: String
    let pendingAssessments: Int
    let onFeelingTap: () -> Void
    let onActivitiesTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(greeting)
                        .font(AppFont.body(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.80))
                    Text(fullName)
                        .font(AppFont.display(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                if pendingAssessments > 0 {
                    VStack(spacing: 2) {
                        Text("\(pendingAssessments)")
                            .font(AppFont.body(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("pending")
                            .font(AppFont.body(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if !mainGoal.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Text(mainGoal)
                        .font(AppFont.body(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.88))
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }

            HStack(spacing: 1) {
                Button(action: onFeelingTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13))
                        Text("I’m Feeling")
                            .font(AppFont.body(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.white.opacity(0.15))
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1, height: 26)

                Button(action: onActivitiesTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13))
                        Text("Activities")
                            .font(AppFont.body(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.black.opacity(0.12))
                }
                .buttonStyle(.plain)
            }
            .background(Color.black.opacity(0.10))
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.60, blue: 0.40),
                    AppColor.green,
                    Color(red: 0.28, green: 0.55, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: AppColor.green.opacity(0.32), radius: 14, y: 5)
    }
}
