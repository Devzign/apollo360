//
//  LabMetricsContentView.swift
//  Apollo360
//

import SwiftUI

struct LabMetricsContentView: View {
    @ObservedObject var viewModel: MetricsViewModel
    @Binding var selectedRange: String

    private let ranges = ["1D", "1W", "1M", "3M", "1Y", "All"]

    private var labMetricCards: [MetricCardDisplay] {
        viewModel.cards.filter { $0.dataSource == .lab }
    }

    var body: some View {
        VStack(spacing: 18) {
            if viewModel.isLoading && labMetricCards.isEmpty {
                ProgressView("Loading lab metrics...")
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundColor(AppColor.grey)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
            }

            if let error = viewModel.errorMessage, !error.isEmpty, labMetricCards.isEmpty {
                Text(error)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
            }

            if !viewModel.isLoading && labMetricCards.isEmpty {
                Text("No lab metrics available yet.")
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundColor(AppColor.grey)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
            }

            ForEach(labMetricCards) { card in
                LabMetricCardView(
                    metric: card,
                    selectedRange: selectedRange,
                    ranges: ranges,
                    compareOptions: compareOptions(for: card),
                    isCompareLoading: viewModel.isSavingCompare,
                    onRangeChange: handleRangeChange,
                    onCompareSelect: { option in
                        guard let option else { return }
                        viewModel.compareMetric(baseMetricId: card.id, compareMetricId: option.id)
                    }
                )
            }
        }
    }

    private func handleRangeChange(_ range: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedRange = range
        }
        viewModel.updateRange(range)
    }

    private func compareOptions(for card: MetricCardDisplay) -> [MetricCompareOption] {
        viewModel.compareOptions.filter { $0.metricField != card.metricField }
    }
}
