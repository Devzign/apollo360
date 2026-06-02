import SwiftUI

struct InlineDropdown: View {
    let placeholder: String
    let options: [String]
    @Binding var selected: String
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isOpen.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Text(selected.isEmpty ? placeholder : selected)
                        .font(AppFont.body(size: 15, weight: .regular))
                        .foregroundColor(selected.isEmpty ? Color(red: 0.7, green: 0.7, blue: 0.7) : AppColor.color414141)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.color414141.opacity(0.7))
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isOpen)
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isOpen ? AppColor.green.opacity(0.55) : Color(red: 0.82, green: 0.82, blue: 0.82), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selected = option
                                isOpen = false
                            }
                        } label: {
                            HStack {
                                Text(option)
                                    .font(AppFont.body(size: 15, weight: .regular))
                                    .foregroundColor(AppColor.color414141)
                                Spacer()
                                if selected == option {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppColor.green)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(selected == option ? AppColor.green.opacity(0.05) : Color.white)
                        }
                        .buttonStyle(.plain)

                        if option != options.last {
                            Divider().padding(.horizontal, 12)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                .zIndex(20)
            }
        }
        .zIndex(isOpen ? 20 : 0)
    }
}
