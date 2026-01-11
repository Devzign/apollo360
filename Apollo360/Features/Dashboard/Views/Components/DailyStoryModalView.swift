import SwiftUI
import UIKit

struct DailyStoryModalView: View {
    let story: DailyStory

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppColor.secondary
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text(story.title)
                    .font(AppFont.display(size: 24, weight: .bold))
                    .foregroundStyle(AppColor.black)

                storyContent

                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.black)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.08))
                    )
            }
            .padding(.trailing, 20)
            .padding(.top, 16)
        }
    }

    @ViewBuilder
    private var storyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let imageName = story.imageName,
               let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else if let iconURL = story.iconURL {
                AsyncImage(url: iconURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                    } else if phase.error != nil {
                        placeholderContent
                    } else {
                        ProgressView()
                            .frame(height: 180)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            if let headline = story.headline {
                Text(headline)
                    .font(AppFont.display(size: 22, weight: .bold))
                    .foregroundStyle(AppColor.black)
            }

            if let detail = story.detail {
                Text(detail)
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(AppColor.grey)
                    .lineSpacing(2)
            }

            if let recommendation = story.recommendation {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommendation")
                        .font(AppFont.body(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.primary)

                    Text(recommendation)
                        .font(AppFont.body(size: 14))
                        .foregroundStyle(AppColor.black)
                }
                .padding()
                .background(AppColor.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if story.headline == nil && story.detail == nil && story.recommendation == nil {
                Text("We will share highlights from your data soon.")
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.grey)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var placeholderContent: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.black.opacity(0.04))
            .frame(height: 180)
            .overlay(
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.grey)
            )
    }
}

#Preview {
    DailyStoryModalView(
        story: DailyStory(
            title: "RPM",
            systemImage: "waveform.path.ecg",
            tint: AppColor.green,
            hasUpdate: true,
            isViewed: false,
            imageName: "dailySnapRPM",
            headline: "Your sleep quality improved to 7.5 hours average",
            detail: "Your sleep isn’t always fully restful",
            recommendation: "Keep your bedtime routine consistent"
        )
    )
}
