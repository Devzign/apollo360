//
//  AuthShell.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

struct AuthShell<Content: View>: View {
    private let content: Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 30 : 24
    }
    
    private var cardMaxWidth: CGFloat? {
        horizontalSizeClass == .regular ? 520 : 380
    }
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            AppColor.green.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                    .frame(height: 64)
                Image("apolloLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .padding(.bottom, 16)
                
                Spacer()
                
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        content
                    }
                    .padding(30)
                    .frame(maxWidth: cardMaxWidth)
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
                    )
                    Spacer()
                }
                .padding(.horizontal, horizontalPadding)
                
                Spacer().frame(height: 32)
            }
        }
    }
}
