//
//  View+ScrollTransition.swift
//  Apollo360
//
//  Created by Codex on 28/01/26.
//

import SwiftUI

extension View {
    /// Fades and scales content based on scroll position without mutating state.
    @ViewBuilder
    func scrollFadeScale() -> some View {
        if #available(iOS 17.0, *) {
            scrollTransition(.animated.threshold(.visible(0.2))) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0.65)
                    .scaleEffect(phase.isIdentity ? 1 : 0.97)
            }
        } else {
            self
        }
    }
}
