//
//  DailyStoriesView.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

struct DailyStoriesView: View {
    let title: String
    let subtitle: String
    let stories: [DailyStory]

    @State private var selectedStory: DailyStory?

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(title)
                    .font(AppFont.display(size: 22, weight: .bold))
                    .foregroundStyle(AppColor.black)
                Text(subtitle)
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.grey)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stories) { story in
                        Button {
                            selectedStory = story
                        } label: {
                            StoryBadgeView(story: story)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .fullScreenCover(item: $selectedStory) { story in
            DailyStoryModalView(story: story)
        }
    }
}

private struct StoryBadgeView: View {
    let story: DailyStory

    private let ringSize: CGFloat = 40
    private let outerSize: CGFloat = 52

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .strokeBorder(ringStyle, lineWidth: 2)
                    .frame(width: ringSize, height: ringSize)
                    .opacity(story.isViewed ? 0.6 : 1.0)
                    .overlay(
                        Circle()
                            .fill(AppColor.secondary)
                            .padding(4)
                    )
                    .overlay(
                        Circle()
                            .fill(story.tint)
                            .padding(5)
                    )

                StoryBadgeIcon(story: story)
            }
            .frame(width: outerSize, height: outerSize)
            .overlay(alignment: .topTrailing) {
                if story.hasUpdate {
                    Circle()
                        .fill(AppColor.primary)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(AppColor.secondary, lineWidth: 2)
                        )
                        .offset(x: -2, y: 2)
                }
            }

            Text(story.title)
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundStyle(AppColor.black)
                .frame(width: 60)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var ringStyle: AnyShapeStyle {
        story.hasUpdate
        ? AnyShapeStyle(ringGradient)
        : AnyShapeStyle(Color.black.opacity(0.08))
    }

    private var ringGradient: LinearGradient {
        LinearGradient(
            colors: [story.tint, story.tint.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct StoryBadgeIcon: View {
    let story: DailyStory
    private let iconSize: CGFloat = 28

    var body: some View {
        Group {
            if let url = story.iconURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if phase.error != nil {
                        Image(systemName: "photo")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundStyle(AppColor.secondary)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            } else if let systemImage = story.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(AppColor.secondary)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(AppColor.secondary)
            }
        }
        .frame(width: iconSize, height: iconSize)
    }
}

#Preview {
    let stories = [
        DailyStory(title: "RPM", systemImage: "waveform.path.ecg", tint: AppColor.green, hasUpdate: true, isViewed: false, imageName: "dailySnapRPM"),
        DailyStory(title: "Labs", systemImage: "testtube.2", tint: AppColor.blue, hasUpdate: true, isViewed: false, imageName: nil),
        DailyStory(title: "Medications", systemImage: "pills", tint: AppColor.yellow, hasUpdate: false, isViewed: true, imageName: nil),
        DailyStory(title: "Chronic Care", systemImage: "cross.case", tint: AppColor.red, hasUpdate: true, isViewed: false, imageName: nil)
    ]

    DailyStoriesView(
        title: "Your Daily Snapshot",
        subtitle: "Personalized stories generated from your data to help you understand trends and take simple, supportive actions.",
        stories: stories
    )
    .padding()
}
