import SwiftUI

struct HomeActionButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .font(AppFont.body(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 12).fill(isPrimary ? AppColor.green : AppColor.color414141))
            .opacity(isDisabled ? 0.55 : (configuration.isPressed ? 0.85 : 1))
    }
}
