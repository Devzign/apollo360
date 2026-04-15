//
//  RPMMetricsContentView.swift
//  Apollo360
//

import SwiftUI

struct RPMMetricsContentView: View {
    @ObservedObject var viewModel: MetricsViewModel
    @Binding var selectedRange: String
    @Binding var isFeeling: Bool

    private let ranges = ["1D", "1W", "1M", "3M", "1Y", "All"]

    private var careTeamCards: [MetricCardDisplay] {
        viewModel.cards.filter { $0.sourceSection == .careTeam && $0.dataSource == .rpm }
    }

    private var myMetricCards: [MetricCardDisplay] {
        viewModel.cards.filter { $0.sourceSection == .myMetrics && $0.dataSource == .rpm }
    }

    var body: some View {
        VStack(spacing: 18) {
            sectionHeader(title: "Added By Care Team", showToggle: true)
            sectionContent(cards: careTeamCards)

            if !myMetricCards.isEmpty {
                sectionHeader(title: "Added by Me", showToggle: false)
                sectionContent(cards: myMetricCards)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, showToggle: Bool) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.8))

            Spacer()

            if showToggle {
                HStack(spacing: 10) {
                    Text("I'm Feeling")
                        .font(AppFont.body(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.black.opacity(0.8))

                    Toggle("", isOn: $isFeeling)
                        .labelsHidden()
                        .toggleStyle(MetricsToggleStyle())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func sectionContent(cards: [MetricCardDisplay]) -> some View {
        VStack(spacing: 18) {
            if viewModel.isLoading && cards.isEmpty {
                ProgressView("Loading metrics...")
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundColor(AppColor.grey)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
            }

            if let error = viewModel.errorMessage, !error.isEmpty, cards.isEmpty {
                Text(error)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
            }

            if let status = viewModel.compareStatusMessage, !status.isEmpty {
                Text(status)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
            }

            if !viewModel.isLoading && cards.isEmpty {
                Text("No metrics available yet.")
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundColor(AppColor.grey)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
            }

            ForEach(cards) { card in
                RPMMetricCardView(
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
