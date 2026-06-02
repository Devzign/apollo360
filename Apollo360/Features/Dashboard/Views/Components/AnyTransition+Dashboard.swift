import SwiftUI

extension AnyTransition {
    static var sideMenu: AnyTransition {
        let insertion = AnyTransition.move(edge: .leading)
            .combined(with: .scale(scale: 0.95, anchor: .leading))
            .combined(with: .opacity)
        let removal = AnyTransition.move(edge: .leading)
            .combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}
