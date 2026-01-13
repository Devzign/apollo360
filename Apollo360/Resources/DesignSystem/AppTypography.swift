//
//  AppTypography.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI
import UIKit

/// Centralized typography helpers that prefer the Space Grotesk display family and Inter for body text.
enum AppTypography {
    static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        customFont(
            candidates: [
                "SpaceGrotesk-Bold",
                "SpaceGrotesk-SemiBold",
                "SpaceGrotesk-Regular",
                "Inter-Bold",
                "Inter-SemiBold",
                "Inter-Regular"
            ],
            size: size,
            fallback: .system(size: size, weight: weight, design: .rounded)
        )
    }

    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        customFont(
            candidates: [
                "Inter-Regular",
                "Inter-Medium",
                "Inter-SemiBold",
                "Inter-Bold",
                "SpaceGrotesk-Regular",
                "SpaceGrotesk-Medium"
            ],
            size: size,
            fallback: .system(size: size, weight: weight, design: .default)
        )
    }

    private static func customFont(candidates: [String], size: CGFloat, fallback: Font) -> Font {
        for name in candidates where UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return fallback
    }
}

typealias AppFont = AppTypography
