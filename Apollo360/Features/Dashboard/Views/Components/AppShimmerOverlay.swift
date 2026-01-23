//
//  AppShimmerOverlay.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct AppShimmerOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppColor.colorECF0F3

                ShimmerGradient()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .mask(placeholder)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .transition(.opacity)
    }

    @ViewBuilder
    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Capsule()
                    .frame(width: 32, height: 6)
                Spacer()
                RoundedRectangle(cornerRadius: 6)
                    .frame(width: 140, height: 28)
                Spacer()
                RoundedRectangle(cornerRadius: 6)
                    .frame(width: 28, height: 28)
            }

            RoundedRectangle(cornerRadius: 20)
                .frame(height: 48)

            ForEach(0..<6, id: \.self) { _ in
                messagePlaceholder
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 140)
    }

    private var messagePlaceholder: some View {
        HStack(spacing: 16) {
            Circle()
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 150, height: 14)
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 200, height: 12)
            }
            Spacer()
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 42, height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 30, height: 10)
            }
        }
    }
}

private struct ShimmerGradient: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            LinearGradient(
                colors: [
                    AppColor.white.opacity(0.3),
                    AppColor.white.opacity(0.9),
                    AppColor.white.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: width * 1.6, height: proxy.size.height * 1.4)
            .rotationEffect(.degrees(25))
            .offset(x: animate ? width : -width)
            .onAppear {
                animate = true
            }
            .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: animate)
        }
    }
}
