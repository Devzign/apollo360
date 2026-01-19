import SwiftUI

struct WellnessProgressRing: View {
    let score: Int
    let progress: Double
    var onTap: (() -> Void)? = nil
    @State private var animatedProgress: Double = 0
    @State private var wavePhase: Double = 0
    @State private var isBumping = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.44, blue: 0.95),
                            Color(red: 0.59, green: 0.8, blue: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 6
                )

            WaveContainerView(progress: animatedProgress, phase: wavePhase)
                .clipShape(Circle())
                .padding(14)

            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 2)

            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(score)")
                        .font(AppFont.display(size: 46, weight: .bold))
                    Text("%")
                        .font(AppFont.body(size: 20, weight: .bold))
                        .baselineOffset(8)
                }

                Text("Overall Score")
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.white)
                Text("Body energy \(score)%")
                    .font(AppFont.body(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.grey)
            }
            .foregroundStyle(AppColor.black)
        }
        .frame(width: 220, height: 220)
        .padding(.vertical, 16)
        .contentShape(Circle())
        .scaleEffect(isBumping ? 1.02 : 1)
        .animation(
            .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
            value: isBumping
        )
        .onTapGesture {
            onTap?()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                wavePhase = 1
            }
            isBumping = true
        }
        .modifier(ProgressChangeHandler(
            progress: progress,
            animatedProgress: $animatedProgress
        ))
    }
}

struct WaveShape: Shape {
    var progress: Double
    var phase: Double
    var amplitude: CGFloat
    var frequency: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let normalizedProgress = max(0, min(1, progress))
        let baseY = height * CGFloat(1 - normalizedProgress)

        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: baseY))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let angle = (relativeX * frequency + phase) * .pi * 2
            let y = baseY + sin(angle) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}

struct WaveContainerView: View {
    var progress: Double
    var phase: Double

    private var fillGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.46, blue: 0.92),
                Color(red: 0.18, green: 0.57, blue: 0.94),
                Color(red: 0.11, green: 0.38, blue: 0.76)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.opacity(0.1)

                WaveShape(progress: progress, phase: phase, amplitude: 18, frequency: 1.4)
                    .fill(fillGradient)
                    .clipped()

                WaveShape(progress: max(0, min(1, progress - 0.07)), phase: phase - 0.4, amplitude: 12, frequency: 1.9)
                    .fill(Color.white.opacity(0.3))

                Circle()
                    .stroke(Color.white.opacity(0.45), lineWidth: 2)
                    .frame(width: geo.size.width * 0.12, height: geo.size.width * 0.12)
                    .offset(
                        x: -geo.size.width * 0.08 + geo.size.width * 0.12 * sin(phase * .pi * 2),
                        y: -geo.size.height * 0.15 + geo.size.height * 0.05 * cos(phase * .pi * 2)
                    )
                    .blendMode(.screen)

                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: geo.size.width * 0.08, height: geo.size.width * 0.08)
                    .offset(x: geo.size.width * 0.22, y: -geo.size.height * 0.1)
                    .blur(radius: 0.6)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct ProgressChangeHandler: ViewModifier {
    let progress: Double
    @Binding var animatedProgress: Double

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .onChange(of: progress) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animatedProgress = progress
                    }
                }
        } else {
            content
                .onChange(of: progress, perform: { newValue in
                    withAnimation(.easeOut(duration: 0.8)) {
                        animatedProgress = newValue
                    }
                })
        }
    }
}

struct WellnessProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        WellnessProgressRing(score: 82, progress: 0.82)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
