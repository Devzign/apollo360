//
//  EnergyWaveCircleView.swift
//  Apollo360
//
//  Created by Amit Sinha on 20/01/26.
//

import SwiftUI

struct EnergyWaveCircleView: View {
    var energy: Double

    @State private var waveOffset: CGFloat = 0

    var body: some View {
        ZStack {

            Circle()
                .stroke(Color.blue.opacity(0.25), lineWidth: 10)

            WaterWave(
                progress: CGFloat(energy / 100),
                waveHeight: 0.05,
                offset: waveOffset
            )
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.8), .blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                Circle()
                    .padding(6)
            )

            VStack(spacing: 4) {
                Text("\(Int(energy))")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.black)

                Text("Overall Score")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 220, height: 220)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = 360
            }
        }
    }
}


struct WaterWave: Shape {
    var progress: CGFloat
    var waveHeight: CGFloat
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            let progressHeight = (1 - progress) * rect.height
            let height = waveHeight * rect.height

            path.move(to: CGPoint(x: 0, y: progressHeight))

            for x in stride(from: 0, through: rect.width, by: 2) {
                let sine = sin(Angle(degrees: x + offset).radians)
                let y = progressHeight + (height * sine)
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
        }
    }
}

struct EnergyWaveCircleView_Previews: PreviewProvider {
    @State static var energy: Double = 72

    static var previews: some View {
        VStack(spacing: 30) {
            EnergyWaveCircleView(energy: energy)

            Slider(value: $energy, in: 0...100)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
