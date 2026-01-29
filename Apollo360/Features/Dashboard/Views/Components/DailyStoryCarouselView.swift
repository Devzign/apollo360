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
    @State private var lastIndex: Int = 0
    @State private var progress: CGFloat = 0
    @Namespace private var storyNamespace
    @State private var isPaused: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDraggingTopCard: Bool = false
    @State private var isPresentingShare: Bool = false
    @State private var shareItems: [Any] = []

    @State private var autoAdvanceTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let autoAdvanceDuration: TimeInterval = 5

    init(stories: [DailyStory], initialIndex: Int) {
        self.stories = stories
        self.initialIndex = min(max(initialIndex, 0), max(stories.count - 1, 0))
        _currentIndex = State(initialValue: self.initialIndex)
        _lastIndex = State(initialValue: self.initialIndex)
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: handleDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
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
                    let cardWidth = proxy.size.width * 0.92
                    let cardHeight = proxy.size.height * 0.92

                    ZStack {
                        ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                            let position = index - currentIndex
                            if position >= 0 && position <= 3 {
                                DailyStoryContentView(story: story, progress: $progress, activeIndex: currentIndex)
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
                                    .scaleEffect(1.0 - CGFloat(position) * 0.06)
                                    .offset(y: CGFloat(position) * 24)
                                    .opacity(position == 0 ? 1 : 0.9 - CGFloat(position) * 0.1)
                                    .rotation3DEffect(.degrees(Double(position) * -4), axis: (x: 0, y: 1, z: 0), perspective: 0.7)
                                    .offset(x: position == 0 && !isPresentingShare ? dragOffset.width : 0,
                                            y: position == 0 && !isPresentingShare ? dragOffset.height : 0)
                                    .rotationEffect(.degrees(position == 0 && !isPresentingShare ? Double(dragOffset.width / 20) : 0))
                                    .zIndex(Double(stories.count - index))
                                    .gesture(
                                        position == 0 && !isPresentingShare ? DragGesture()
                                            .onChanged { value in
                                                if !isDraggingTopCard {
                                                    isDraggingTopCard = true
                                                    pauseProgress()
                                                }
                                                dragOffset = value.translation
                                            }
                                            .onEnded { value in
                                                let velocity = value.predictedEndTranslation
                                                let horizontalTravel = value.translation.width
                                                let threshold: CGFloat = 100
                                                let velocityThreshold: CGFloat = 500

                                                // Decide direction: right swipe -> next, left swipe -> previous (optional)
                                                if abs(horizontalTravel) > threshold || abs(velocity.width) > velocityThreshold {
                                                    if horizontalTravel < 0 { // swipe left -> next
                                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                            dragOffset = CGSize(width: -1000, height: dragOffset.height)
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            goToNext()
                                                            dragOffset = .zero
                                                            isDraggingTopCard = false
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                                resumeProgress()
                                                            }
                                                        }
                                                    } else { // swipe right -> previous
                                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                            dragOffset = CGSize(width: 1000, height: dragOffset.height)
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            goToPrevious()
                                                            dragOffset = .zero
                                                            isDraggingTopCard = false
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                                resumeProgress()
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    // Snap back
                                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                                        dragOffset = .zero
                                                    }
                                                    isDraggingTopCard = false
                                                    resumeProgress()
                                                }
                                            }
                                        : nil
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                pauseButton
                closeButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(autoAdvanceTimer) { _ in
            guard !stories.isEmpty, !isPaused else { return }
            withAnimation(.easeInOut(duration: 0.2)) { progress = 0 }
            withAnimation(.linear(duration: autoAdvanceDuration)) { progress = 1 }
            goToNext(animated: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestShareStory)) { _ in
            pauseProgress()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                dragOffset = .zero
                isDraggingTopCard = false
            }
            shareItems = captureCurrentStoryImage().map { [$0] } ?? [shareTextForCurrentStory()]
            isPresentingShare = true
        }
        .sheet(isPresented: $isPresentingShare, onDismiss: {
            // Ensure the card returns to rest state after sharing
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                dragOffset = .zero
                isDraggingTopCard = false
            }
            resumeProgress()
        }) {
            ShareSheet(items: shareItems.isEmpty ? [shareTextForCurrentStory()] : shareItems)
                .presentationDetents([.medium, .large])
        }
    }

    private func goToNext(animated: Bool = true) {
        lastIndex = currentIndex
        guard !stories.isEmpty else { return }
        if currentIndex < stories.count - 1 {
            if animated {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    currentIndex += 1
                }
            } else {
                currentIndex += 1
            }
        } else {
            handleDismiss()
        }
        withAnimation(.easeInOut(duration: 0.2)) { progress = 0 }
    }

    private func goToPrevious(animated: Bool = true) {
        guard currentIndex > 0 else { return }
        lastIndex = currentIndex
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                currentIndex -= 1
            }
        } else {
            currentIndex -= 1
        }
        withAnimation(.easeInOut(duration: 0.2)) { progress = 0 }
    }

    private func handleDismiss() {
        dismiss()
    }

    private func pauseProgress() {
        autoAdvanceTimer.upstream.connect().cancel()
    }

    private func resumeProgress() {
        autoAdvanceTimer = Timer.publish(every: autoAdvanceDuration, on: .main, in: .common).autoconnect()
        withAnimation(.easeInOut(duration: 0.2)) { progress = 0 }
        withAnimation(.linear(duration: autoAdvanceDuration)) { progress = 1 }
    }

    private func shareTextForCurrentStory() -> String {
        guard stories.indices.contains(currentIndex) else { return "" }
        let story = stories[currentIndex]
        var parts: [String] = []
        parts.append(story.title)
        if let headline = story.headline { parts.append(headline) }
        if let recommendation = story.recommendation { parts.append(recommendation) }
        return parts.joined(separator: "\n\n")
    }

    private func captureCurrentStoryImage() -> UIImage? {
        guard stories.indices.contains(currentIndex) else { return nil }
        let story = stories[currentIndex]
        let renderer = ImageRenderer(
            content: DailyStoryContentView(story: story, progress: .constant(progress), activeIndex: currentIndex)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private var pauseButton: some View {
        VStack {
            HStack {
                Button {
                    togglePause()
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.45)))
                }

                Spacer()
            }
            Spacer()
        }
        .padding(.top, 20)
        .padding(.leading, 20)
    }

    private func togglePause() {
        isPaused.toggle()

        if isPaused {
            pauseProgress()
        } else {
            resumeProgress()
        }
    }
}

private struct DailyStoryContentView: View {
    let story: DailyStory
    @Binding var progress: CGFloat
    let activeIndex: Int

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
        let tint = story.tint

        return Group {
            RoundedRectangle(cornerRadius: 0)
                .fill(tintGradient(tint))
        }
        .overlay(
            LinearGradient(
                colors: [
                    tint.opacity(0.35),
                    Color.black.opacity(0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tintGradient(_ tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.55),
                tint.opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var profileIcon: some View {
        if let iconURL = story.iconURL {
            AsyncImage(url: iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
        } else {
            Circle()
                .fill(story.tint.opacity(0.7))
                .frame(width: 12, height: 12)
        }
    }

    private var storyProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * max(0, progress))
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
    }

    private var storyInfoRow: some View {
        HStack(spacing: 12) {
            profileIcon

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
        VStack(alignment: .leading, spacing: 10) {

            if let headline = story.headline {
                Text(headline)
                    .font(AppFont.display(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
            }

            if let recommendation = story.recommendation {
                TypewriterText(
                    text: recommendation,
                    speed: 0.05,
                    font: AppFont.body(size: 14, weight: .medium),
                    color: Color.white
                )
                .id("\(story.id)-\(activeIndex)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(nil, value: story.id)
        .animation(nil, value: progress)
    }
    
    private var storyBottomBar: some View {
        HStack(spacing: 16) {
            Spacer()
            HStack(spacing: 18) {
                Button {
                    NotificationCenter.default.post(name: .requestShareStory, object: nil)
                } label: {
                    Image(systemName: "paperplane")
                }
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

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension Notification.Name {
    static let requestShareStory = Notification.Name("DailyStoryCarouselView.requestShareStory")
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
        ),
        
        DailyStory(
            title: "amitSinha",
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
