import SwiftUI

struct WrapChipsView: View {
    let items: [String]
    @Binding var selection: Set<String>

    var body: some View {
        FlowLayout(items: items, spacing: 8) { value in
            Button(value) {
                if selection.contains(value) {
                    selection.remove(value)
                } else {
                    selection.insert(value)
                }
            }
            .font(AppFont.body(size: 13, weight: .medium))
            .foregroundColor(selection.contains(value) ? .white : AppColor.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(selection.contains(value) ? AppColor.green : Color(red: 0.92, green: 0.96, blue: 0.92)))
        }
    }
}
