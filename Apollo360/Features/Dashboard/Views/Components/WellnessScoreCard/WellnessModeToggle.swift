import SwiftUI

struct WellnessModeToggle: View {
    @Binding var selected: WellnessMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(WellnessMode.allCases, id: \.self) { mode in
                Text(mode.rawValue)
                    .font(AppFont.body(size: 12, weight: .semibold))
                    .foregroundStyle(mode == selected ? AppColor.secondary : AppColor.grey)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(mode == selected ? AppColor.primary : Color.clear)
                    .clipShape(Capsule())
                    .onTapGesture {
                        selected = mode
                    }
            }
        }
        .padding(3)
        .background(Color.black.opacity(0.05))
        .clipShape(Capsule())
    }
}

struct WellnessModeToggle_Previews: PreviewProvider {
    @State static var currentMode: WellnessMode = .absolute

    static var previews: some View {
        WellnessModeToggle(selected: $currentMode)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
