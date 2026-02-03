import SwiftUI

struct SettingRow: View {
    let item: SettingItem

    var body: some View {
        HStack(spacing: 14) {
            Text(item.title)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.black)
                .lineLimit(2)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColor.black.opacity(0.6))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppColor.primary.opacity(0.15))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
    }
}
