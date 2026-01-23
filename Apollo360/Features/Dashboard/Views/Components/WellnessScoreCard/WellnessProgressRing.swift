import SwiftUI

struct WellnessProgressRing: View {
    let score: Int
    let progress: Double
    @State private var animatedProgress: Double = 0
    @State private var pulse: CGFloat = 1

    private var clampedProgress: Double {
        max(0, min(progress, 1))
    }

    private var ringSize: CGFloat {
        isiPad() ? 240 : 220
    }

    private var ringLineWidth: CGFloat {
        isiPad() ? 16 : 14
    }

    var body: some View {
        let haloColor = AppColor.blue.opacity(0.4)

        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColor.blue.opacity(0.22),
                            Color.gray.opacity(0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: ringLineWidth
                )

            Circle()
                .stroke(haloColor, lineWidth: ringLineWidth + 26)
                .blur(radius: 28)
                .scaleEffect(pulse)
                .opacity(1)

            Circle()
                .stroke(haloColor.opacity(0.72), lineWidth: ringLineWidth + 16)
                .blur(radius: 18)
                .scaleEffect(pulse)
                .opacity(0.95)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [AppColor.blue, AppColor.blue.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: AppColor.blue.opacity(0.3),
                    radius: 18,
                    y: 10
                )
                .overlay(
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(AppColor.blue.opacity(0.45), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 4)
                        .opacity(0.9)
                )

            VStack(spacing: 6) {
                Text("\(score)")
                    .font(AppFont.display(size: 46, weight: .bold))
                    .foregroundStyle(AppColor.black)

                Text("Overall Score")
                    .font(AppFont.body(size: 12))
                    .foregroundStyle(AppColor.grey)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = clampedProgress
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = 1.08
            }
        }
        .modifier(ProgressChangeHandler(
            progress: clampedProgress,
            animatedProgress: $animatedProgress
        ))
    }
}

private struct ProgressChangeHandler: ViewModifier {
    let progress: Double
    @Binding var animatedProgress: Double

    func body(content: Content) -> some View {
        content
            .onChange(of: progress) { newValue in
                withAnimation(.easeInOut(duration: 0.9)) {
                    animatedProgress = newValue
                }
            }
    }
}

#Preview("Wellness Ring - iPhone") {
    WellnessProgressRing(score: 78, progress: 0.78)
        .padding()
        .frame(width: 260, height: 260)
        .environment(\.horizontalSizeClass, .compact)
        .background(Color.black.opacity(0.02))
}

#Preview("Wellness Ring - iPad") {
    WellnessProgressRing(score: 82, progress: 0.82)
        .padding()
        .frame(width: 300, height: 300)
        .environment(\.horizontalSizeClass, .regular)
        .background(Color.black.opacity(0.02))
}
