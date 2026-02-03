import SwiftUI
import UIKit

struct FormInputField: View {
    let label: String
    @Binding var value: String
    var placeholder: String? = nil
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFont.body(size: 12, weight: .semibold))
                .foregroundStyle(AppColor.grey)

            TextField(placeholder ?? label, text: $value)
                .font(AppFont.body(size: 16))
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColor.colorECF0F3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppColor.grey.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}
