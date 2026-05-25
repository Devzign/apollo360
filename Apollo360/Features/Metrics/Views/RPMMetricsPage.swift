import SwiftUI

struct RPMMetricsPage: View {
    let horizontalPadding: CGFloat
    @ObservedObject var viewModel: MetricsViewModel

    @State private var selectedRange = "1Y"
    @State private var isFeeling = false
    @State private var isInfoVisible = true
    @State private var isShowingMetricSelector = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                titleBar

                if isInfoVisible {
                    metricsInfoCard(
                        title: "What is this?",
                        message: "Within this section, you can explore all of the health data that's relevant to your health journey. These analytics are monitored real time, and with your doctor's help can provide you with more ways to reach your health goals.",
                        dismiss: { isInfoVisible = false }
                    )
                }

                RPMMetricsContentView(
                    viewModel: viewModel,
                    selectedRange: $selectedRange,
                    isFeeling: $isFeeling
                )
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(metricsPageBackgroundView.ignoresSafeArea())
        .navigationTitle("RPM Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setActiveSource(.rpm)
        }
        .sheet(isPresented: $isShowingMetricSelector) {
            RPMMetricSelectionSheet(
                categories: viewModel.rpmSelectionCategories,
                isLoading: viewModel.isLoadingRPMSelections,
                isSaving: viewModel.isSavingRPMSelections,
                errorMessage: viewModel.rpmSelectionErrorMessage,
                onDismiss: { isShowingMetricSelector = false },
                onAppear: {
                    if viewModel.rpmSelectionCategories.isEmpty {
                        viewModel.loadRPMMetricSelections()
                    }
                },
                onRefresh: {
                    viewModel.loadRPMMetricSelections()
                },
                onSave: { selectedMetricIds in
                    viewModel.saveRPMMetricSelections(selectedMetricIds: selectedMetricIds) {
                        isShowingMetricSelector = false
                    }
                }
            )
        }
    }

    private var titleBar: some View {
        HStack(spacing: 12) {
            Text("RPM Metrics")
                .font(AppFont.body(size: 19, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.82))

            Spacer()

            Button(action: {
                isShowingMetricSelector = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Select Metrics")
                        .font(AppFont.body(size: 14, weight: .semibold))
                        .fixedSize()
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColor.green.opacity(0.82))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.84))
        )
    }
}
