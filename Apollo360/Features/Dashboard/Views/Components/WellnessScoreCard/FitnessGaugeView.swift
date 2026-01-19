import SwiftUI

import SwiftUI

struct FitnessGaugeView: View {

    var value: Double

    @State private var animatedValue: Double = 0
    @State private var pulse = false
    @State private var pulseWorkItem: DispatchWorkItem?
    @State private var hasInitialized = false

    // MARK: Gauge segments (UNCHANGED)
    private let segments: [GaugeSegment] = [
        .init(start: 180, end: 220, color: .red),
        .init(start: 220, end: 260, color: .orange),
        .init(start: 260, end: 300, color: .yellow),
        .init(start: 300, end: 340, color: .green.opacity(0.7)),
        .init(start: 340, end: 360, color: .green)
    ]

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                ForEach(segments.indices, id: \.self) { index in
                    GaugeArc(
                        startAngle: segments[index].start,
                        endAngle: segments[index].end
                    )
                    .stroke(
                        segments[index].color,
                        style: StrokeStyle(
                            lineWidth: 50,
                            lineCap: .round
                        )
                    )
                    .scaleEffect(isActive(index) && pulse ? 1.06 : 1.0)
                    .shadow(
                        color: isActive(index)
                            ? segments[index].color.opacity(0.6)
                            : .clear,
                        radius: isActive(index) ? 10 : 0
                    )
                }

                Capsule()
                    .fill(Color.black)
                    .frame(width: 4, height: 120)
                    .position(x: 140, y: 120)
                    .rotationEffect(.degrees(needleAngle), anchor: .bottom)
                    .animation(.easeOut(duration: 1.1), value: animatedValue)
                    .zIndex(10)


                Circle()
                    .fill(Color.black.opacity(0.50))
                    .frame(width: 10, height: 10)
                    .position(x: 140, y: 160)
                    .zIndex(11)
            }
            .frame(width: 280, height: 160)

            HStack {
                Text("LOW")
                    .foregroundColor(.red)
                    .font(.headline)

                Spacer()

                Text("HIGH")
                    .foregroundColor(.green)
                    .font(.headline)
            }
            .padding(.horizontal, 26)
            .padding(.top, 20)
        }
        .onAppear {
            updateValue(to: value)
        }
        .onChange(of: value) { newValue in
            updateValue(to: newValue)
        }
    }

    private var needleAngle: Double {
        // Clamp
        let v = min(max(animatedValue, 0), 100)

        // Map 0–100 → −90° … +90°
        return (-90) + (v / 100) * 180
    }

    // MARK: Active segment (UNCHANGED)
    private func isActive(_ index: Int) -> Bool {
        index == activeSegmentIndex
    }

    private var activeSegmentIndex: Int {
        let normalizedValue = min(max(animatedValue, 0), 100)
        let segmentSize = 100.0 / Double(segments.count)
        let rawIndex = Int(normalizedValue / segmentSize)
        return min(segments.count - 1, max(0, rawIndex))
    }

    // MARK: Pulse animation (UNCHANGED)
    private func startPulse() {
        pulseWorkItem?.cancel()
        pulse = false

        let workItem = DispatchWorkItem {
            withAnimation(
                .easeInOut(duration: 0.7)
                    .repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }

        pulseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

    private func updateValue(to newValue: Double) {
        let clamped = min(max(newValue, 0), 100)
        withAnimation(.easeOut(duration: 1.1)) {
            animatedValue = clamped
        }

        if hasInitialized {
            startPulse()
        } else {
            hasInitialized = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                startPulse()
            }
        }

    }
}


struct GaugeArc: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path
    }
}

struct GaugeSegment {
    let start: Double
    let end: Double
    let color: Color
}


struct FitnessGaugeView_Previews: PreviewProvider {
    @State private static var fitnessScore: Double = 87

    static var previews: some View {
        VStack(spacing: 24) {
            FitnessGaugeView(value: fitnessScore)
            Slider(value: $fitnessScore, in: 0...100)
                .padding(.horizontal)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
