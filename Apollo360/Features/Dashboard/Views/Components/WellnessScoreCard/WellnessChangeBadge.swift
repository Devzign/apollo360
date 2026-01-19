import SwiftUI

struct WellnessChangeBadge: View {
    let isImproving: Bool
    let changeValue: Int

    var body: some View {
        HStack(spacing: 8) {
            Image("arrow_relative")
                .resizable()
                .renderingMode(.template)
                .frame(width: 26, height: 20)
                .font(.system(size: 14, weight: .bold))
            Text("\(isImproving ? "+" : "")\(changeValue) points")
                .font(AppFont.body(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background((isImproving ? AppColor.green : AppColor.red).opacity(0.12))
        .foregroundStyle(isImproving ? AppColor.green : AppColor.red)
        .clipShape(Capsule())
    }
}

struct WellnessChangeBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            WellnessChangeBadge(isImproving: true, changeValue: 5)
            WellnessChangeBadge(isImproving: false, changeValue: 3)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
