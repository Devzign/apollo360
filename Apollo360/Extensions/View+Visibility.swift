//
//  View+Visibility.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import SwiftUI

private struct VisibilityModifier: ViewModifier {
    let onVisible: () -> Void
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { update(proxy) }
                        .onChange(of: proxy.frame(in: .global)) { _, _ in
                            update(proxy)
                        }
                }
            )
    }

    private func update(_ proxy: GeometryProxy) {
        let frame = proxy.frame(in: .global)
        let screen = UIScreen.main.bounds
        let nowVisible = frame.intersects(screen)

        if nowVisible && !isVisible {
            isVisible = true
            onVisible()
        } else if !nowVisible {
            isVisible = false
        }
    }
}

extension View {
    /// Triggers the action once each time the view becomes visible in the global coordinate space.
    func onBecomeVisible(perform action: @escaping () -> Void) -> some View {
        modifier(VisibilityModifier(onVisible: action))
    }
}
