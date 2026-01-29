//
//  AppColors.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

enum AppColor {
    static let primary = Color("AppPrimary")
    static let secondary = Color("AppSecondary")
    static let white = Color("AppWhite")
    static let black = Color("AppBlack")
    static let grey = Color("grey")
    static let blue = Color("AppBlue")
    static let yellow = Color("AppYellow")
    static let green = Color("AppGreen")
    static let red = Color("AppRed")
    static let colorECF0F3 = Color("colorECF0F3")
}

extension Color {
    func isDark() -> Bool {
        let uiColor = UIColor(self)
        var white: CGFloat = 0
        uiColor.getWhite(&white, alpha: nil)
        return white < 0.5
    }
}
