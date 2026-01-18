//
//  DailyStoryCarouselView.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI
import UIKit
import Combine
import Kingfisher

struct DailyStoryCarouselView: View {
    let stories: [DailyStory]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    @State private var autoAdvanceTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    init(stories: [DailyStory], initialIndex: Int) {
        self.stories = stories
        self.initialIndex = min(max(initialIndex, 0), max(stories.count - 1, 0))
        _currentIndex = State(initialValue: self.initialIndex)
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: handleDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.45)))
                }
            }
            Spacer()
        }
        .padding(.top, 20)
        .padding(.trailing, 20)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.96)
                .ignoresSafeArea()

            if stories.isEmpty {
                Text("No stories yet.")
                    .foregroundStyle(Color.white.opacity(0.8))
                    .font(AppFont.body(size: 16, weight: .medium))
            } else {
                GeometryReader { proxy in
                    let cardWidth = proxy.size.width
                    let cardHeight = proxy.size.height

                    TabView(selection: $currentIndex) {
                        ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                            DailyStoryContentView(story: story)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(width: cardWidth, height: cardHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .fill(Color.black)
                            .shadow(color: Color.black.opacity(0.35), radius: 30, x: 0, y: 12)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }

                tapRegions
                closeButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(autoAdvanceTimer) { _ in
            guard !stories.isEmpty else { return }
            goToNext()
        }
    }

    private var tapRegions: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: goToPrevious)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: goToNext)
        }
        .ignoresSafeArea()
    }

    private func goToNext() {
        if currentIndex < stories.count - 1 {
            currentIndex += 1
        } else {
            handleDismiss()
        }
    }

    private func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    private func handleDismiss() {
        dismiss()
    }

}

private struct DailyStoryContentView: View {
    let story: DailyStory

    var body: some View {
        ZStack {
            storyBackground

            VStack {
                headerStack
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                Spacer()

                storyHeadline
                    .padding(.horizontal, 24)

                Spacer()

                storyBottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headerStack: some View {
        VStack(spacing: 12) {
            storyProgressBar
            storyInfoRow
        }
    }

    private var storyBackground: some View {
        Group {
            if let imageName = story.imageName,
               let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if let iconURL = story.iconURL {
                KFImage(iconURL)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(defaultGradient)
                    }
                    .fade(duration: 0.25)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(defaultGradient)
            }
        }
        .overlay(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private var defaultGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.18, green: 0.01, blue: 0.49), Color(red: 0.16, green: 0.06, blue: 0.43)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var storyProgressBar: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.95), Color.white.opacity(0.4)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 4)
            .shadow(color: Color.white.opacity(0.4), radius: 4, x: 0, y: 1)
    }

    private var storyInfoRow: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                )
                .overlay(
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white)
                )
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(story.title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                if let detail = story.detail {
                    Text(detail)
                        .font(AppFont.body(size: 13))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }

            Spacer()

            Text("7h")
                .font(AppFont.body(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))

            Image(systemName: "ellipsis")
                .foregroundStyle(Color.white.opacity(0.9))
        }
    }

    private var storyHeadline: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let headline = story.headline {
                Text(headline)
                    .font(AppFont.display(size: 34, weight: .semibold))
                    .foregroundStyle(Color.white)
            }

            if let recommendation = story.recommendation {
                Text(recommendation)
                    .font(AppFont.body(size: 15))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var storyBottomBar: some View {
        HStack(spacing: 16) {
            Spacer()
            HStack(spacing: 18) {
                Image(systemName: "heart")
                Image(systemName: "paperplane")
            }
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.95))
        }
        .foregroundStyle(Color.white.opacity(0.9))
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }
}

#Preview {
    let stories = [
        DailyStory(
            title: "_ritu.u_",
            systemImage: "waveform.path.ecg",
            tint: AppColor.green,
            hasUpdate: true,
            isViewed: false,
            imageName: "dailySnapRPM",
            headline: "Good night 😴",
            detail: "Cozy Corners >",
            recommendation: "∞ Boomerang"
        )
    ]

    DailyStoryCarouselView(stories: stories, initialIndex: 0)
}
