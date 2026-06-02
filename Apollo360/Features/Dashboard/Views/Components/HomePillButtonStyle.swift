import SwiftUI

struct HomePillButtonStyle: ButtonStyle {
    let isDark: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .background((isDark ? Color.black.opacity(0.18) : Color.clear).clipShape(Capsule()))
            .clipShape(Capsule())
    }
}
