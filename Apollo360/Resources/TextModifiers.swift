//
//  AppFontStyle.swift
//  Apollo360
//
//  Created by Amit Sinha on 13/01/26.
//


import SwiftUI
import UIKit

// MARK: - Font Styles
enum AppFontStyle: String {

    // MARK: Poppins
    case poppinsThin            = "Poppins-Thin"
    case poppinsThinItalic      = "Poppins-ThinItalic"
    case poppinsExtraLight      = "Poppins-ExtraLight"
    case poppinsExtraLightItalic = "Poppins-ExtraLightItalic"
    case poppinsLight           = "Poppins-Light"
    case poppinsLightItalic     = "Poppins-LightItalic"
    case poppinsRegular         = "Poppins-Regular"
    case poppinsItalic          = "Poppins-Italic"
    case poppinsMedium          = "Poppins-Medium"
    case poppinsMediumItalic    = "Poppins-MediumItalic"
    case poppinsSemiBold        = "Poppins-SemiBold"
    case poppinsSemiBoldItalic  = "Poppins-SemiBoldItalic"
    case poppinsBold            = "Poppins-Bold"
    case poppinsBoldItalic      = "Poppins-BoldItalic"
    case poppinsExtraBold       = "Poppins-ExtraBold"
    case poppinsExtraBoldItalic = "Poppins-ExtraBoldItalic"
    case poppinsBlack           = "Poppins-Black"
    case poppinsBlackItalic     = "Poppins-BlackItalic"
}


public var iPhoneFont10 = CGFloat(10)
public var iPhoneFont11 = CGFloat(11)
public var iPhoneFont12 = CGFloat(12)
public var iPhoneFont13 = CGFloat(13)
public var iPhoneFont14 = CGFloat(14)
public var iPhoneFont15 = CGFloat(15)
public var iPhoneFont18 = CGFloat(18)
public var iPhoneFont20 = CGFloat(20)
public var iPhoneFont21 = CGFloat(21)
public var iPhoneFont22 = CGFloat(22)
public var iPhoneFont25 = CGFloat(25)
public var iPhoneFont28 = CGFloat(28)
public var iPhoneFont40 = CGFloat(40)
public var iPhoneFont50 = CGFloat(50)


extension UIFont {
    
    static func appFont(_ font: AppFontStyle, size: CGFloat) -> UIFont {
        UIFont(name: font.rawValue, size: size) ?? .systemFont(ofSize: size)
    }
}


extension Text {
    
    func fontModifier(
        font: AppFontStyle,
        size: CGFloat,
        kerning: CGFloat = 0,
        color: Color = .white
    ) -> Text {
        
        let isIphone8 = UIDevice.current.name == "iPhone 8"
        var dSize = size
        
        if isiPad() {
            dSize += 13
        } else if isIphone8 {
            dSize -= (size > 15) ? 3 : 0
        }
        
        return self
            .foregroundColor(color)
            .font(.custom(font.rawValue, size: dSize))
            .kerning(kerning)
    }
}


func isiPad() -> Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}
