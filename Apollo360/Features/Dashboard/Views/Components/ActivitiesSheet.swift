import SwiftUI

struct ActivitiesSheet: View {
    @ObservedObject var viewModel: HomeNewViewModel
    let onSaved: () -> Void
    let onCancel: () -> Void

    @State private var selectedCategory = ""
    @State private var selectedMetricId: Int?
    @State private var notes = ""
    @State private var valueText = ""
    @State private var dropdownSelection = ""

    private var categories: [DashboardLookupCategory] { viewModel.lookupCategories }
    private var selectedCategoryModel: DashboardLookupCategory? { categories.first(where: { $0.category == selectedCategory }) }
    private var selectedMetric: DashboardLookupMetric? { selectedCategoryModel?.metrics.first(where: { $0.id == selectedMetricId }) }
    private var metricOptions: [String] { selectedCategoryModel?.metrics.map { $0.type } ?? [] }
    private var canSave: Bool {
        !viewModel.isSavingActivity && selectedMetric != nil && !valueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color(red: 0.20, green: 0.52, blue: 0.76), Color(red: 0.28, green: 0.68, blue: 0.80)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 76)

                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.22)).frame(width: 38, height: 38)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activities")
                            .font(AppFont.display(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Log your daily activity")
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

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Category", systemImage: "tag")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(categories) { category in
                                    let isSelected = selectedCategory == category.category
                                    let accent = colorFor(category.category)
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.18)) {
                                            selectedCategory = category.category
                                            selectedMetricId = nil
                                            dropdownSelection = ""
                                            valueText = ""
                                        }
                                    } label: {
                                        HStack(spacing: 7) {
                                            Image(systemName: iconFor(category.category))
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(isSelected ? .white : accent)
                                            Text(category.category)
                                                .font(AppFont.body(size: 14, weight: .semibold))
                                                .foregroundColor(isSelected ? .white : AppColor.color414141)
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 40)
                                        .background(Capsule().fill(isSelected ? accent : accent.opacity(0.10)))
                                        .overlay(
                                            Capsule().stroke(isSelected ? Color.clear : accent.opacity(0.30), lineWidth: 1)
                                        )
                                        .shadow(color: isSelected ? accent.opacity(0.35) : .clear, radius: 6, y: 3)
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.18), value: isSelected)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Activity type", systemImage: "list.bullet")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)

                        InlineDropdown(
                            placeholder: selectedCategory.isEmpty ? "Select a category first" : "Select type",
                            options: metricOptions,
                            selected: $dropdownSelection
                        )
                        .onChange(of: dropdownSelection) { newValue in
                            selectedMetricId = selectedCategoryModel?.metrics.first(where: { $0.type == newValue })?.id
                            valueText = ""
                        }
                        .opacity(selectedCategory.isEmpty ? 0.50 : 1)
                        .disabled(selectedCategory.isEmpty)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            selectedMetric?.unit.isEmpty == false ? selectedMetric!.unit : "Value / Units",
                            systemImage: "number"
                        )
                        .font(AppFont.body(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.color414141)

                        TextField("Enter value", text: $valueText)
                            .keyboardType(.decimalPad)
                            .font(AppFont.body(size: 15, weight: .regular))
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color(red: 0.84, green: 0.84, blue: 0.84), lineWidth: 1)
                                    )
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (optional)", systemImage: "square.and.pencil")
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.color414141)

                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Add any additional notes…")
                                    .font(AppFont.body(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.72, green: 0.72, blue: 0.72))
                                    .padding(.top, 12)
                                    .padding(.leading, 14)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $notes)
                                .font(AppFont.body(size: 14, weight: .regular))
                                .frame(height: 80)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .scrollContentBackground(.hidden)
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
                    guard let metric = selectedMetric else { return }
                    viewModel.saveActivity(metric: metric, categoryName: selectedCategory, valueText: valueText, note: notes) { success in
                        if success { onSaved() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSavingActivity {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        }
                        Text(viewModel.isSavingActivity ? "Saving…" : "Save Activity")
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
        .onAppear {
            if selectedCategory.isEmpty {
                selectedCategory = categories.first?.category ?? ""
            }
        }
    }

    private func iconFor(_ category: String) -> String {
        switch category.lowercased() {
        case "nutrition": return "fork.knife"
        case "behavior": return "brain.head.profile"
        case "fitness": return "figure.run"
        default: return "chart.bar.fill"
        }
    }

    private func colorFor(_ category: String) -> Color {
        switch category.lowercased() {
        case "nutrition": return Color(red: 0.25, green: 0.70, blue: 0.45)
        case "behavior": return Color(red: 0.40, green: 0.52, blue: 0.88)
        case "fitness": return Color(red: 0.92, green: 0.55, blue: 0.22)
        default: return AppColor.green
        }
    }
}
