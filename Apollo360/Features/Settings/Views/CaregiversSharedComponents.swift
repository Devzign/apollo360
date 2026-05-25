import SwiftUI

func caregiverPageHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(AppFont.display(size: 26, weight: .semibold))
            .foregroundColor(AppColor.color414141)

        Text(subtitle)
            .font(AppFont.body(size: 14))
            .foregroundColor(AppColor.grey)
    }
}

func caregiverActionHeader(title: String,
                           countText: String,
                           actionTitle: String,
                           action: @escaping () -> Void) -> some View {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.body(size: 18, weight: .semibold))
                .foregroundColor(AppColor.black)
            Text("\(countText) total")
                .font(AppFont.body(size: 13))
                .foregroundColor(AppColor.grey)
        }

        Spacer()

        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                Text(actionTitle)
            }
            .font(AppFont.body(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColor.green.opacity(0.18))
            .foregroundColor(AppColor.green)
            .clipShape(Capsule())
        }
    }
}

func caregiverListCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(spacing: 0) {
        content()
    }
    .padding(.horizontal, 18)
    .background(
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    )
}

func caregiverEmptyState(text: String) -> some View {
    VStack(spacing: 10) {
        Image(systemName: "tray")
            .font(.system(size: 28, weight: .medium))
            .foregroundColor(AppColor.grey)
        Text(text)
            .font(AppFont.body(size: 14))
            .foregroundColor(AppColor.grey)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .background(
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    )
}

func caregiverContactRow(title: String, subtitle: String?, badge: String, deleteAction: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(AppFont.body(size: 16, weight: .semibold))
            .foregroundColor(AppColor.black)

        if let subtitle {
            Text(subtitle)
                .font(AppFont.body(size: 13))
                .foregroundColor(AppColor.grey)
        }

        Text(badge)
            .font(AppFont.body(size: 12, weight: .semibold))
            .foregroundColor(AppColor.green)
    }
    .padding(.vertical, 14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .contextMenu {
        Button(action: deleteAction) {
            Label("Remove", systemImage: "trash")
        }
    }
    .overlay(
        Divider()
            .offset(y: 0.5),
        alignment: .bottom
    )
}

private func caregiverFieldIcon(_ label: String) -> String {
    switch label.lowercased() {
    case let text where text.contains("email"):
        return "envelope.fill"
    case let text where text.contains("phone"):
        return "phone.fill"
    case let text where text.contains("fax"):
        return "printer.fill"
    case let text where text.contains("address"):
        return "mappin.circle.fill"
    case let text where text.contains("organization"):
        return "building.2.fill"
    case let text where text.contains("first"):
        return "person.fill"
    case let text where text.contains("last"):
        return "person.text.rectangle.fill"
    case let text where text.contains("name"):
        return "person.fill"
    default:
        return "pencil"
    }
}

private func caregiverFieldColor(_ label: String) -> Color {
    switch label.lowercased() {
    case let text where text.contains("email"):
        return Color(red: 0.30, green: 0.55, blue: 0.95)
    case let text where text.contains("phone"):
        return Color(red: 0.25, green: 0.72, blue: 0.45)
    case let text where text.contains("fax"):
        return Color(red: 0.65, green: 0.45, blue: 0.90)
    case let text where text.contains("address"):
        return Color(red: 0.95, green: 0.45, blue: 0.35)
    case let text where text.contains("organization"):
        return Color(red: 0.92, green: 0.60, blue: 0.20)
    default:
        return AppColor.green
    }
}

private func caregiverKeyboardType(for label: String) -> UIKeyboardType {
    let lower = label.lowercased()
    if lower.contains("phone") || lower.contains("fax") {
        return .phonePad
    }
    if lower.contains("email") {
        return .emailAddress
    }
    return .default
}

private func caregiverIconField(label: String, binding: Binding<String>, icon: String, iconColor: Color) -> some View {
    HStack(spacing: 14) {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(iconColor.opacity(0.12))
                .frame(width: 38, height: 38)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconColor)
        }

        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(AppFont.body(size: 11, weight: .semibold))
                .foregroundColor(AppColor.grey)
                .textCase(.uppercase)
                .tracking(0.4)

            TextField(label, text: binding)
                .font(AppFont.body(size: 15, weight: .medium))
                .foregroundColor(AppColor.black)
                .keyboardType(caregiverKeyboardType(for: label))
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
    .padding(.vertical, 10)
    .overlay(Divider(), alignment: .bottom)
}

func caregiverContactFormSheet(title: String,
                               icon: String = "plus.circle.fill",
                               headerColor: Color = AppColor.green,
                               fields: [(String, Binding<String>)],
                               submitTitle: String,
                               isSubmitting: Bool,
                               inlineError: String?,
                               onDismiss: (() -> Void)? = nil,
                               submitAction: @escaping () -> Void) -> some View {
    VStack(spacing: 0) {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [headerColor, headerColor.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 110)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFont.display(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Fill in the details below")
                        .font(AppFont.body(size: 12))
                        .foregroundColor(.white.opacity(0.80))
                }

                Spacer()

                if let onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.90))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.white.opacity(0.20)))
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }

        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    ForEach(Array(fields.enumerated()), id: \.offset) { _, pair in
                        let label = pair.0
                        let binding = pair.1
                        caregiverIconField(
                            label: label,
                            binding: binding,
                            icon: caregiverFieldIcon(label),
                            iconColor: caregiverFieldColor(label)
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)

                if let errorMsg = inlineError {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                        Text(errorMsg)
                            .font(AppFont.body(size: 13))
                            .foregroundColor(.red)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }

                Spacer(minLength: 24)
            }
        }
        .background(AppColor.secondary)

        Divider()

        Button(action: submitAction) {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(isSubmitting ? "Saving..." : submitTitle)
                    .font(AppFont.body(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSubmitting ? headerColor.opacity(0.60) : headerColor)
                    .shadow(color: headerColor.opacity(0.35), radius: 10, y: 4)
            )
        }
        .disabled(isSubmitting)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    .background(AppColor.secondary.ignoresSafeArea())
    .ignoresSafeArea(edges: .bottom)
}
