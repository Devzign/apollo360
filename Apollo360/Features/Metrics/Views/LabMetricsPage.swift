import SwiftUI

struct LabMetricsPage: View {
    let horizontalPadding: CGFloat
    @ObservedObject var viewModel: MetricsViewModel

    @State private var selectedRange = "1Y"
    @State private var isInfoVisible = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                titleBar

                if isInfoVisible {
                    metricsInfoCard(
                        title: "What is this?",
                        message: "Please note these lab values are intended to be used for trending purposes only. Each individual value should be verified if being used for diagnostic or treatment decisions.",
                        dismiss: { isInfoVisible = false }
                    )
                }

                LabMetricsContentView(
                    viewModel: viewModel,
                    selectedRange: $selectedRange
                )
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(metricsPageBackgroundView.ignoresSafeArea())
        .navigationTitle("Lab Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setActiveSource(.lab)
        }
    }

    private var titleBar: some View {
        HStack(spacing: 12) {
            Text("LAB Metrics")
                .font(AppFont.body(size: 19, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.82))

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.84))
        )
    }
}
