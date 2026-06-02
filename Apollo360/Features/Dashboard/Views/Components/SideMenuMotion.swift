import SwiftUI

struct SideMenuMotion: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.92, anchor: .leading)
            .rotation3DEffect(
                .degrees(isVisible ? 0 : -12),
                axis: (x: 0, y: 1, z: 0),
                anchor: .leading,
                perspective: 0.7
            )
            .shadow(color: Color.black.opacity(0.4), radius: 30, y: 18)
    }
}
