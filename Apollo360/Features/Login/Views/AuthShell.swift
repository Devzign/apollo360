//
//  AuthShell.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

struct AuthShell<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                AppColor.green.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text("apollo")
                            .font(AppFont.display(size: 56, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 48)
                    Spacer()
                }

                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 0) {
                        content
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 26)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 30)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.white
                            .cornerRadius(40, corners: [.topLeft, .topRight])
                            .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: -12)
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
