//
//  TopRoundedRectangle.swift
//  Apollo360
//
//  Created by Amit Sinha on 17/01/26.
//

import SwiftUI

struct TopRoundedRectangle: Shape {
    var cornerRadius: CGFloat = 32

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}
