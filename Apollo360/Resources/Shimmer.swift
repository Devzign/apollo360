import SwiftUI

private struct ShimmerModifier: ViewModifier {
    @State private var move = false

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        AppColor.white.opacity(0.2),
                        AppColor.white.opacity(0.85),
                        AppColor.white.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(18))
                .offset(x: move ? 280 : -280)
                .animation(.linear(duration: 1.15).repeatForever(autoreverses: false), value: move)
            )
            .mask(content)
            .onAppear { move = true }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
