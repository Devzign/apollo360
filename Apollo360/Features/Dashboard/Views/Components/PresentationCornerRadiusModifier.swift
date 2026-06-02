import SwiftUI

struct PresentationCornerRadiusModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCornerRadius(radius)
        } else {
            content
        }
    }
}
