//
//  MetricsView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct MetricsView: View {
    @State private var selectedRange = "1D"
    @State private var isFeeling = false
    @State private var compareBaseMetric: MetricCardDisplay?
    @State private var selectedCompareMetricId: String = ""
    @StateObject private var viewModel: MetricsViewModel
    let horizontalPadding: CGFloat

    private let ranges = ["1D", "1W", "1M", "3M", "1Y", "All"]

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        _viewModel = StateObject(wrappedValue: MetricsViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                InfoCard()

                sectionHeader(title: "Added by Care Team", showToggle: true)

                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Loading metrics...")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.grey)
                    }

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(AppFont.body(size: 13, weight: .medium))
                            .foregroundColor(AppColor.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let status = viewModel.compareStatusMessage, !status.isEmpty {
                        Text(status)
                            .font(AppFont.body(size: 13, weight: .medium))
                            .foregroundColor(AppColor.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !viewModel.isLoading && viewModel.cards.isEmpty {
                        Text("No metrics available yet.")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.grey)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(careTeamCards) { card in
                        MetricCardView(
                            metric: card,
                            selectedRange: selectedRange,
                            ranges: ranges,
                            onRangeChange: { range in
                                withAnimation {
                                    selectedRange = range
                                }
                                viewModel.updateRange(range)
                            },
                            onCompareTap: {
                                compareBaseMetric = card
                                selectedCompareMetricId = viewModel.compareOptions
                                    .first(where: { $0.id != card.id })?
                                    .id ?? ""
                            }
                        )
                    }
                }

                if !myMetricCards.isEmpty {
                    sectionHeader(title: "Added by Me", showToggle: false)

                    VStack(spacing: 20) {
                        ForEach(myMetricCards) { card in
                            MetricCardView(
                                metric: card,
                                selectedRange: selectedRange,
                                ranges: ranges,
                                onRangeChange: { range in
                                    withAnimation {
                                        selectedRange = range
                                    }
                                    viewModel.updateRange(range)
                                },
                                onCompareTap: {
                                    compareBaseMetric = card
                                    selectedCompareMetricId = viewModel.compareOptions
                                        .first(where: { $0.id != card.id })?
                                        .id ?? ""
                                }
                            )
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .onAppear {
            selectedRange = viewModel.selectedRange
            viewModel.loadIfNeeded()
        }
        .sheet(item: $compareBaseMetric) { baseMetric in
            CompareMetricSheet(
                baseMetric: baseMetric,
                compareOptions: viewModel.compareOptions.filter { $0.id != baseMetric.id },
                selectedCompareMetricId: $selectedCompareMetricId,
                isSaving: viewModel.isSavingCompare,
                onCancel: {
                    compareBaseMetric = nil
                },
                onSave: {
                    guard !selectedCompareMetricId.isEmpty else { return }
                    viewModel.compareMetric(baseMetricId: baseMetric.id, compareMetricId: selectedCompareMetricId)
                    compareBaseMetric = nil
                }
            )
        }
    }

    private var careTeamCards: [MetricCardDisplay] {
        viewModel.cards.filter { $0.sourceSection == .careTeam }
    }

    private var myMetricCards: [MetricCardDisplay] {
        viewModel.cards.filter { $0.sourceSection == .myMetrics }
    }

    @ViewBuilder
    private func sectionHeader(title: String, showToggle: Bool) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.7))

            Spacer()

            if showToggle {
                Toggle("I'm Feeling", isOn: $isFeeling)
                    .toggleStyle(SwitchToggleStyle(tint: AppColor.green))
                    .labelsHidden()
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func InfoCard() -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What is this?")
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.black)

                Text("Within this section, you can explore all of the health data that's relevant to your health journey. These analytics are monitored real time, and with your doctor's help can provide you with more ways to reach your health goals.")
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.black.opacity(0.65))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColor.grey.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColor.green.opacity(0.14))
        )
    }
}

private struct MetricCardView: View {
    let metric: MetricCardDisplay
    let selectedRange: String
    let ranges: [String]
    let onRangeChange: (String) -> Void
    let onCompareTap: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            header
            ChartView(points: metric.points, rangeText: metric.dateRange)
            RangeSelector(ranges: ranges, selectedRange: selectedRange, onSelect: onRangeChange)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(metric.title)
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundColor(AppColor.black)

                Spacer()

                if metric.isLabAvailable {
                    Text("Lab")
                        .font(AppFont.body(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColor.green.opacity(0.16)))
                }

                Button(action: onCompareTap) {
                    HStack(spacing: 6) {
                        Text("Compare")
                            .font(AppFont.body(size: 14))
                            .foregroundColor(AppColor.green)
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColor.green)
                    }
                    .padding(8)
                    .background(Capsule().fill(AppColor.green.opacity(0.16)))
                }
                .buttonStyle(.plain)
            }

            if let detail = metric.detailText, !detail.isEmpty {
                Text(detail)
                    .font(AppFont.body(size: 12))
                    .foregroundColor(AppColor.grey)
                    .lineLimit(2)
            }

            Text("Last: \(metric.lastValue)\(unitSuffix)  Average: \(metric.averageValue)\(unitSuffix)")
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.black.opacity(0.7))

            if let comparedWith = metric.comparedWith {
                Text("Compared with: \(comparedWith)")
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundColor(AppColor.green)
            }
        }
    }

    private var unitSuffix: String {
        guard let unit = metric.unit, !unit.isEmpty else { return "" }
        return " \(unit)"
    }
}

private struct CompareMetricSheet: View {
    let baseMetric: MetricCardDisplay
    let compareOptions: [MetricFolderItem]
    @Binding var selectedCompareMetricId: String
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Compare \(baseMetric.title) with")
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.black)

                if compareOptions.isEmpty {
                    Text("No compare metrics available.")
                        .font(AppFont.body(size: 14))
                        .foregroundColor(AppColor.grey)
                } else {
                    Picker("Compare Metric", selection: $selectedCompareMetricId) {
                        ForEach(compareOptions, id: \.id) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 180)
                }

                Button(action: onSave) {
                    Text(isSaving ? "Saving..." : "Save Comparison")
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppColor.green)
                        )
                }
                .disabled(compareOptions.isEmpty || selectedCompareMetricId.isEmpty || isSaving)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Compare Metric")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .onAppear {
            if selectedCompareMetricId.isEmpty {
                selectedCompareMetricId = compareOptions.first?.id ?? ""
            }
        }
    }
}

private struct ChartView: View {
    let points: [Double]
    let rangeText: String

    var body: some View {
        GeometryReader { proxy in
            let fill = LinearGradient(
                colors: [AppColor.green.opacity(0.3), AppColor.green.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )

            ZStack(alignment: .bottomLeading) {
                SparklineShape(points: points, closes: true)
                    .fill(fill)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                SparklineShape(points: points)
                    .stroke(AppColor.green, lineWidth: 2.5)
            }
            .overlay(
                Text(rangeText)
                    .font(AppFont.body(size: 12))
                    .foregroundColor(AppColor.grey)
                    .padding(.bottom, 8),
                alignment: .bottomLeading
            )
        }
        .frame(height: 180)
    }
}

private struct SparklineShape: Shape {
    let points: [Double]
    var closes: Bool = false

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }
        let minValue = points.min() ?? 0
        let maxValue = points.max() ?? 1
        let verticalScale = maxValue - minValue == 0 ? 1 : maxValue - minValue

        let step = rect.width / CGFloat(points.count - 1)

        return Path { path in
            for index in points.indices {
                let x = CGFloat(index) * step
                let normalized = (points[index] - minValue) / verticalScale
                let y = rect.height * (1 - normalized)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            if closes {
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))
                path.addLine(to: CGPoint(x: 0, y: rect.height))
                path.closeSubpath()
            }
        }
    }
}

private struct RangeSelector: View {
    let ranges: [String]
    let selectedRange: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ranges, id: \.self) { range in
                Button(action: { onSelect(range) }) {
                    Text(range)
                        .font(AppFont.body(size: 12, weight: .semibold))
                        .foregroundColor(range == selectedRange ? AppColor.green : AppColor.grey)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(range == selectedRange ? AppColor.green.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("iPhone") {
    MetricsView(horizontalPadding: 20, session: SessionManager())
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPad") {
    MetricsView(horizontalPadding: 50, session: SessionManager())
        .environment(\.horizontalSizeClass, .regular)
}
