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

    @Namespace private var storyNamespace
    @State private var selectedStoryIndex: Int?
    @State private var backgroundTint: Color = AppColor.secondary
    @State private var activeStory: DailyStory?
    @State private var showHero = false
    @State private var showCarousel = false

    var body: some View {
        ZStack {
            mainContent

            if let activeStory {
                heroCircle(for: activeStory)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { showCarousel && selectedStoryIndex != nil },
                set: { if !$0 { showCarousel = false; resetHero() } }
            ),
            onDismiss: resetHero
        ) {
            if let index = selectedStoryIndex {
                DailyStoryCarouselView(stories: stories, initialIndex: index)
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 12) {
            header

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                        StoryBadgeView(
                            story: story,
                            namespace: storyNamespace,
                            isHidden: activeStory?.id == story.id && showHero
                        ) {
                            handleTap(on: story, index: index)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(12)
        .background(backgroundTint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: backgroundTint)
    }

    private var header: some View {
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
    }
    private func handleTap(on story: DailyStory, index: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            backgroundTint = story.tint
            activeStory = story
            showHero = true
        }

        selectedStoryIndex = index

        // start carousel after hero scales up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showCarousel = true
        }
    }

    private func resetHero() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            showHero = false
            activeStory = nil
        }
        selectedStoryIndex = nil
    }

    @ViewBuilder
    private func heroCircle(for story: DailyStory) -> some View {
        GeometryReader { proxy in
            Circle()
                .fill(story.tint)
                .matchedGeometryEffect(id: story.id, in: storyNamespace, isSource: false)
                .frame(width: showHero ? max(proxy.size.height, proxy.size.width) * 1.2 : 70,
                       height: showHero ? max(proxy.size.height, proxy.size.width) * 1.2 : 70)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .opacity(showHero ? 1 : 0)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

private struct StoryBadgeView: View {
    let story: DailyStory
    let namespace: Namespace.ID
    let isHidden: Bool
    let onTap: () -> Void

    private let ringSize: CGFloat = 70
    private let outerSize: CGFloat = 70

    private let iconSize: CGFloat = 45

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(ringStyle, lineWidth: 2)
                        .frame(width: ringSize, height: ringSize)
                        .opacity(story.isViewed ? 0.6 : 1.0)
                        .overlay(
                            Circle()
                                .fill(story.tint.opacity(0.16))
                                .padding(8)
                        )
                        .overlay(
                            Circle()
                                .fill(story.tint)
                                .padding(5)
                        )
                        .overlay {
                            StoryBadgeIcon(story: story, iconSize: iconSize)
                        }
                        .matchedGeometryEffect(id: story.id, in: namespace)
                        .opacity(isHidden ? 0 : 1)
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
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.black)
                    .frame(width: 80)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .buttonStyle(.plain)
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
    let iconSize: CGFloat

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
                            .foregroundStyle(story.tint)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            } else if let systemImage = story.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(story.tint)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(story.tint)
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
