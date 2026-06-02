import SwiftUI

struct FeelingSheet: View {
    @ObservedObject var viewModel: HomeNewViewModel
    let onSaved: () -> Void
    let onCancel: () -> Void
    @State private var selectedSymptom = ""
    @State private var note = ""

    private let options = ["Chest pain", "Palpitations", "Trouble breathing", "Dizzy", "Fatigue", "Pain", "Anxious", "Happy", "Sad"]
    private let chipColors: [Color] = [
        Color(red: 1.0, green: 0.87, blue: 0.87),
        Color(red: 0.87, green: 0.94, blue: 1.0),
        Color(red: 0.95, green: 0.88, blue: 1.0),
        Color(red: 0.88, green: 0.97, blue: 0.91),
        Color(red: 1.0, green: 0.94, blue: 0.84)
    ]
    private var recentSymptoms: [DashboardRecentSymptom] { Array(viewModel.recentSymptoms.prefix(4)) }
    private var canSave: Bool {
        !viewModel.isSavingFeeling && (!selectedSymptom.isEmpty || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [AppColor.green.opacity(0.88), AppColor.green.opacity(0.60)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 76)

                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.22)).frame(width: 38, height: 38)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I’m Feeling")
                            .font(AppFont.display(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Log how you’re feeling right now")
                            .font(AppFont.body(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.82))
                    }
                    Spacer()
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.20)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
            .cornerRadius(0)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if !recentSymptoms.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColor.green)
                                Text("Recent")
                                    .font(AppFont.body(size: 13, weight: .semibold))
                                    .foregroundColor(AppColor.color414141)
                            }
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                                spacing: 8
                            ) {
                                ForEach(recentSymptoms.indices, id: \.self) { idx in
                                    let item = recentSymptoms[idx]
                                    let bg = chipColors[idx % chipColors.count]
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(AppColor.green.opacity(0.65))
                                            .frame(width: 7, height: 7)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.symptoms)
                                                .font(AppFont.body(size: 12, weight: .semibold))
                                                .foregroundColor(AppColor.color414141)
                                                .lineLimit(1)
                                            Text(formattedDate(item.createdAt))
                                                .font(AppFont.body(size: 10, weight: .medium))
                                                .foregroundColor(AppColor.green.opacity(0.85))
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(bg)
                                    )
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("How you are feeling", systemImage: "face.smiling")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                        InlineDropdown(placeholder: "Select a symptom", options: options, selected: $selectedSymptom)
                    }

                    HStack(spacing: 10) {
                        Rectangle().fill(Color(red: 0.88, green: 0.88, blue: 0.88)).frame(height: 1)
                        Text("or type below")
                            .font(AppFont.body(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.62, green: 0.62, blue: 0.62))
                            .fixedSize()
                        Rectangle().fill(Color(red: 0.88, green: 0.88, blue: 0.88)).frame(height: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Describe how you’re feeling", systemImage: "pencil.line")
                                .font(AppFont.body(size: 13, weight: .semibold))
                                .foregroundColor(AppColor.color414141)
                            Spacer()
                            Text("\(note.count)/25")
                                .font(AppFont.body(size: 11, weight: .medium))
                                .foregroundColor(note.count >= 25 ? AppColor.green : Color(red: 0.70, green: 0.70, blue: 0.70))
                        }
                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("Type here (max 25 characters)…")
                                    .font(AppFont.body(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.72, green: 0.72, blue: 0.72))
                                    .padding(.top, 12)
                                    .padding(.leading, 14)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $note)
                                .font(AppFont.body(size: 14, weight: .regular))
                                .frame(height: 88)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .scrollContentBackground(.hidden)
                                .onChange(of: note) { newValue in
                                    if newValue.count > 25 { note = String(newValue.prefix(25)) }
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(red: 0.84, green: 0.84, blue: 0.84), lineWidth: 1)
                                )
                        )
                    }

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                            Text(error)
                                .font(AppFont.body(size: 12, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.07)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }

            Divider()
            VStack(spacing: 10) {
                Button {
                    let selected = selectedSymptom.isEmpty ? [] : [selectedSymptom]
                    viewModel.saveFeeling(selected: selected, note: note) { success in
                        if success { onSaved() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSavingFeeling {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        }
                        Text(viewModel.isSavingFeeling ? "Saving…" : "Save")
                    }
                }
                .buttonStyle(HomeActionButtonStyle(isPrimary: true, isDisabled: !canSave))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 30, x: 0, y: 8)
        .frame(maxWidth: 390)
    }

    private func formattedDate(_ raw: String) -> String {
        let input = ISO8601DateFormatter()
        if let date = input.date(from: raw) {
            let output = DateFormatter()
            output.dateFormat = "MM/dd/yyyy"
            return output.string(from: date)
        }
        return String(raw.prefix(10))
    }
}
