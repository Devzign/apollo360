//
//  AppTypography.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI
import UIKit

/// Centralized typography helpers that use the Poppins family across the app.
enum AppTypography {
    static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        customFont(
            candidates: [
                "Poppins-Black",
                "Poppins-BlackItalic",
                "Poppins-ExtraBold",
                "Poppins-ExtraBoldItalic",
                "Poppins-Bold",
                "Poppins-BoldItalic",
                "Poppins-SemiBold",
                "Poppins-SemiBoldItalic"
            ],
            size: size,
            fallback: .system(size: size, weight: weight, design: .default)
        )
    }

    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        customFont(
            candidates: [
                "Poppins-Regular",
                "Poppins-Italic",
                "Poppins-Light",
                "Poppins-LightItalic",
                "Poppins-Medium",
                "Poppins-MediumItalic",
                "Poppins-SemiBold",
                "Poppins-SemiBoldItalic",
                "Poppins-ExtraLight",
                "Poppins-ExtraLightItalic",
                "Poppins-Thin",
                "Poppins-ThinItalic"
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
