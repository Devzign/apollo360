//
//  TypewriterText.swift
//  Apollo360
//
//  Created by Amit Sinha on 28/01/26.
//

import SwiftUI

struct TypewriterText: View {
    let text: String
    let speed: Double
    var font: Font = AppFont.body(size: 12)
    var color: Color = AppColor.grey

    @State private var revealedCount: Int = 0
    @State private var typingTask: Task<Void, Never>?

    private var displayedText: String {
        String(text.prefix(revealedCount))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Reserve full layout height
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .opacity(0)
                .accessibilityHidden(true)

            Text(displayedText)
                .font(font)
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onBecomeVisible { startTyping() }
        .onChange(of: text) { _, _ in resetAndStart() }
        .onDisappear {
            typingTask?.cancel()
        }
    }

    private func resetAndStart() {
        typingTask?.cancel()
        revealedCount = 0

        typingTask = Task {
            for index in text.indices {
                try? await Task.sleep(nanoseconds: UInt64(speed * 1_000_000_000))
                if Task.isCancelled { return }
                await MainActor.run {
                    revealedCount = text.distance(from: text.startIndex, to: text.index(after: index))
                }
            }
        }
    }

    private func startTyping() {
        resetAndStart()
    }
}
