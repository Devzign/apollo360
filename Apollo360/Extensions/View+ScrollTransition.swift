//
//  View+ScrollTransition.swift
//  Apollo360
//
//  Created by Amit Sinha on 28/01/26.
//

import SwiftUI

extension View {
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
