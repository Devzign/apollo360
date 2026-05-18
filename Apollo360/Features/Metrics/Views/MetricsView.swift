//
//  MetricsView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct MetricsView: View {
    private enum MetricsTab: String {
        case rpm = "RPM Metrics"
        case lab = "Lab Metrics"

        var source: MetricDataSource {
            switch self {
            case .rpm: return .rpm
            case .lab: return .lab
            }
        }
    }

    @State private var selectedRange = "1Y"
    @State private var isFeeling = false
    @State private var isInfoVisible = true
    @State private var selectedTab: MetricsTab = .rpm
    @State private var isShowingMetricSelector = false
    @StateObject private var viewModel: MetricsViewModel
    let horizontalPadding: CGFloat

    private let ranges = ["1D", "1W", "1M", "3M", "1Y", "All"]

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        _viewModel = StateObject(wrappedValue: MetricsViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                metricsTitleBar
                metricsTabBar

                if isInfoVisible {
                    infoCard(for: selectedTab)
                }

                if selectedTab == .rpm {
                    RPMMetricsContentView(
                        viewModel: viewModel,
                        selectedRange: $selectedRange,
                        isFeeling: $isFeeling
                    )
                } else {
                    LabMetricsContentView(
                        viewModel: viewModel,
                        selectedRange: $selectedRange
                    )
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(backgroundView.ignoresSafeArea())
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .onChange(of: selectedTab) { newTab in
            viewModel.setActiveSource(newTab.source)
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

    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 247 / 255, green: 250 / 255, blue: 246 / 255),
                Color(red: 241 / 255, green: 247 / 255, blue: 241 / 255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var metricsTitleBar: some View {
        HStack(spacing: 12) {
            Text(selectedTab == .rpm ? "RPM Metrics" : "LAB Metrics")
                .font(AppFont.body(size: 19, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.82))

            Spacer()

            if selectedTab == .rpm {
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
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.84))
        )
    }

    private var metricsTabBar: some View {
        HStack(spacing: 16) {
            tabButton(.rpm)
            tabButton(.lab)
        }
        .padding(.horizontal, 2)
    }

    private func tabButton(_ tab: MetricsTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            Text(tab.rawValue)
                .font(AppFont.body(size: 17, weight: .semibold))
                .foregroundColor(selectedTab == tab ? .white : AppColor.black.opacity(0.82))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(selectedTab == tab ? AppColor.green.opacity(0.82) : Color.white.opacity(0.92))
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func infoCard(for tab: MetricsTab) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What is this?")
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.green.opacity(0.85))

                Text(infoText(for: tab))
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.green.opacity(0.72))
                    .lineSpacing(2)
            }

            Spacer(minLength: 8)

            Button(action: { isInfoVisible = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.green.opacity(0.7))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 227 / 255, green: 241 / 255, blue: 226 / 255))
        )
    }

    private func infoText(for tab: MetricsTab) -> String {
        switch tab {
        case .rpm:
            return "Within this section, you can explore all of the health data that's relevant to your health journey. These analytics are monitored real time, and with your doctor's help can provide you with more ways to reach your health goals."
        case .lab:
            return "Please note these lab values are intended to be used for trending purposes only. Each individual value should be verified if being used for diagnostic or treatment decisions."
        }
    }
}

struct RPMMetricCardView: View {
    let metric: MetricCardDisplay
    let selectedRange: String
    let ranges: [String]
    let compareOptions: [MetricCompareOption]
    let isCompareLoading: Bool
    let onRangeChange: (String) -> Void
    let onCompareSelect: (MetricCompareOption?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topSummary
            latestReading
            compareSelector
            chartPanel
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(red: 221 / 255, green: 226 / 255, blue: 220 / 255), lineWidth: 1)
                )
        )
        .overlay(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(red: 188 / 255, green: 194 / 255, blue: 186 / 255))
                .frame(width: 3, height: 52)
                .padding(.trailing, 8)
        }
    }

    private var topSummary: some View {
        HStack(alignment: .top, spacing: 12) {
            summaryBlock(title: metric.title, value: metric.unit.map { "\(metric.lastValue) \($0)" } ?? metric.lastValue)
            summaryBlock(title: "Last", value: metric.unit.map { "\(metric.lastValue) \($0)" } ?? metric.lastValue)
            summaryBlock(title: "Average", value: metric.unit.map { "\(metric.averageValue) \($0)" } ?? metric.averageValue)
        }
    }

    private func summaryBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.82))

                if title == metric.title, metric.dataSource == .lab {
                    Text("Lab")
                        .font(AppFont.body(size: 10, weight: .semibold))
                        .foregroundColor(AppColor.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppColor.green.opacity(0.14)))
                }
            }

            Text(value)
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var latestReading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Latest Reading")
                .font(AppFont.body(size: 12))
                .foregroundColor(AppColor.grey)

            Text(metric.dateRange)
                .font(AppFont.body(size: 14, weight: .medium))
                .foregroundColor(AppColor.black.opacity(0.78))

            if let detail = metric.detailText, !detail.isEmpty {
                Text(detail)
                    .font(AppFont.body(size: 11))
                    .foregroundColor(AppColor.grey.opacity(0.9))
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
    }

    private var compareSelector: some View {
        Menu {
            Button("No Selection") {
                onCompareSelect(nil)
            }

            if !rpmCompareOptions.isEmpty {
                Section("RPM") {
                    ForEach(rpmCompareOptions) { option in
                        Button {
                            onCompareSelect(option)
                        } label: {
                            if metric.comparedMetricId == option.id {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }
                }
            }

            if !labCompareOptions.isEmpty {
                Section("Lab") {
                    ForEach(labCompareOptions) { option in
                        Button {
                            onCompareSelect(option)
                        } label: {
                            if metric.comparedMetricId == option.id {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }
                }
            }

            if compareOptions.isEmpty {
                Button("No compare metrics available.") {}
                    .disabled(true)
            }
        } label: {
            HStack(spacing: 10) {
                Text(isCompareLoading ? "Loading..." : (metric.comparedWith ?? "No Selection"))
                    .font(AppFont.body(size: 15, weight: .medium))
                    .foregroundColor(metric.comparedWith == nil ? AppColor.color414141.opacity(0.82) : AppColor.green)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.grey.opacity(0.9))
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.86))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(red: 221 / 255, green: 226 / 255, blue: 220 / 255), lineWidth: 1)
                    )
            )
        }
        .disabled(isCompareLoading)
    }

    private var chartPanel: some View {
        VStack(spacing: 0) {
            RangeSelector(ranges: ranges, selectedRange: selectedRange, onSelect: onRangeChange)
                .padding(.horizontal, 10)
                .padding(.top, 10)

            ChartView(points: metric.points, rangeText: metric.dateRange, title: metric.title)
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 10)
        }
        .background(Color.white.opacity(0.82))
    }

    private var rpmCompareOptions: [MetricCompareOption] {
        compareOptions.filter { $0.category == .rpm }
    }

    private var labCompareOptions: [MetricCompareOption] {
        compareOptions.filter { $0.category == .lab }
    }
}

struct LabMetricCardView: View {
    let metric: MetricCardDisplay
    let selectedRange: String
    let ranges: [String]
    let compareOptions: [MetricCompareOption]
    let isCompareLoading: Bool
    let onRangeChange: (String) -> Void
    let onCompareSelect: (MetricCompareOption?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                labSummaryBlock(title: metric.title, value: nil)
                labSummaryBlock(title: "Last:", value: metric.lastValue)
                labSummaryBlock(title: "Average:", value: metric.averageValue)
            }

            Text("Latest Reading on \(metric.dateRange)")
                .font(AppFont.body(size: 14, weight: .medium))
                .foregroundColor(AppColor.color414141.opacity(0.84))

            labCompareSelector

            VStack(spacing: 0) {
                RangeSelector(ranges: ranges, selectedRange: selectedRange, onSelect: onRangeChange)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)

                ChartView(points: metric.points, rangeText: metric.dateRange, title: metric.title)
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
            }
            .background(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 228 / 255, green: 232 / 255, blue: 228 / 255), lineWidth: 1)
                )
        )
    }

    private func labSummaryBlock(title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            if let value {
                Text(value)
                    .font(AppFont.body(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var labCompareSelector: some View {
        Menu {
            Button("No Selection") {
                onCompareSelect(nil)
            }

            if !rpmCompareOptions.isEmpty {
                Section("RPM") {
                    ForEach(rpmCompareOptions) { option in
                        Button(option.title) { onCompareSelect(option) }
                    }
                }
            }

            if !labCompareOptions.isEmpty {
                Section("Lab") {
                    ForEach(labCompareOptions) { option in
                        Button(option.title) { onCompareSelect(option) }
                    }
                }
            }

            if compareOptions.isEmpty {
                Button("No compare metrics available.") {}
                    .disabled(true)
            }
        } label: {
            HStack {
                Text(isCompareLoading ? "Loading..." : (metric.comparedWith ?? "No Selection"))
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundColor(AppColor.color414141.opacity(0.8))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.grey.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(red: 226 / 255, green: 229 / 255, blue: 227 / 255), lineWidth: 1)
                    )
            )
        }
        .disabled(isCompareLoading)
    }

    private var rpmCompareOptions: [MetricCompareOption] {
        compareOptions.filter { $0.category == .rpm }
    }

    private var labCompareOptions: [MetricCompareOption] {
        compareOptions.filter { $0.category == .lab }
    }
}

struct RPMMetricSelectionSheet: View {
    let categories: [RPMMetricSelectionCategory]
    let isLoading: Bool
    let isSaving: Bool
    let errorMessage: String?
    let onDismiss: () -> Void
    let onAppear: () -> Void
    let onRefresh: () -> Void
    let onSave: ([Int]) -> Void

    @State private var selectedCategoryID: String = ""
    @State private var selectedMetricIDs: Set<Int> = []

    var body: some View {
        NavigationView {
            VStack(spacing: 14) {
                if isLoading && categories.isEmpty {
                    Spacer()
                    ProgressView("Loading metrics...")
                        .font(AppFont.body(size: 14, weight: .medium))
                    Spacer()
                } else if let errorMessage, !errorMessage.isEmpty, categories.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        Text(errorMessage)
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.red)
                            .multilineTextAlignment(.center)

                        Button("Retry", action: onRefresh)
                            .font(AppFont.body(size: 15, weight: .semibold))
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                } else {
                    categoryTabs
                    metricList
                    footer
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .navigationTitle("Select Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColor.grey)
                    }
                }
            }
        }
        .onAppear {
            onAppear()
            hydrateSelectionIfNeeded()
        }
        .onChange(of: categories) { _ in
            hydrateSelectionIfNeeded(force: true)
        }
    }

    private var selectedCategory: RPMMetricSelectionCategory? {
        categories.first(where: { $0.id == selectedCategoryID }) ?? categories.first
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    Button(action: { selectedCategoryID = category.id }) {
                        Text(category.title)
                            .font(AppFont.body(size: 12, weight: .semibold))
                            .foregroundColor(selectedCategoryID == category.id ? .white : AppColor.grey.opacity(0.95))
                            .padding(.horizontal, 12)
                            .frame(height: 28)
                            .background(
                                Capsule()
                                    .fill(selectedCategoryID == category.id ? AppColor.green.opacity(0.82) : Color(red: 246 / 255, green: 247 / 255, blue: 248 / 255))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var metricList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                if let selectedCategory {
                    ForEach(selectedCategory.availableMetrics + selectedCategory.unavailableMetrics) { metric in
                        RPMMetricSelectionRow(
                            metric: metric,
                            isSelected: selectedMetricIDs.contains(metric.id),
                            onToggle: { toggle(metric) }
                        )
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(action: onDismiss) {
                Text("Cancel")
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundColor(AppColor.color414141)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(red: 244 / 255, green: 246 / 255, blue: 246 / 255))
                    )
            }
            .buttonStyle(.plain)

            Button(action: {
                onSave(selectedMetricIDs.sorted())
            }) {
                Text(isSaving ? "Saving..." : "Save")
                    .font(AppFont.body(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColor.green.opacity(0.82))
                    )
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .padding(.vertical, 8)
    }

    private func hydrateSelectionIfNeeded(force: Bool = false) {
        guard force || selectedCategoryID.isEmpty else { return }
        selectedCategoryID = categories.first?.id ?? ""
        selectedMetricIDs = Set(
            categories
                .flatMap { $0.availableMetrics + $0.unavailableMetrics }
                .filter(\.isChecked)
                .map(\.id)
        )
    }

    private func toggle(_ metric: RPMMetricSelectionItem) {
        guard metric.isAvailable, !metric.isDisabled else { return }
        if selectedMetricIDs.contains(metric.id) {
            selectedMetricIDs.remove(metric.id)
        } else {
            selectedMetricIDs.insert(metric.id)
        }
    }
}

private struct RPMMetricSelectionRow: View {
    let metric: RPMMetricSelectionItem
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(checkmarkColor)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.description)
                        .font(AppFont.body(size: 14, weight: .semibold))
                        .foregroundColor(titleColor)
                        .multilineTextAlignment(.leading)

                    Text(metric.metric)
                        .font(AppFont.body(size: 11))
                        .foregroundColor(AppColor.grey.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !metric.glossaryDisplay.isEmpty {
                        Text(metric.glossaryDisplay)
                            .font(AppFont.body(size: 11))
                            .foregroundColor(AppColor.grey.opacity(0.72))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(AppColor.grey.opacity(0.6))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(metric.isDisabled ? Color.white.opacity(0.55) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .opacity(metric.isDisabled ? 0.65 : 1)
        }
        .buttonStyle(.plain)
        .disabled(metric.isDisabled || !metric.isAvailable)
    }

    private var checkmarkColor: Color {
        if metric.isDisabled {
            return Color(red: 221 / 255, green: 228 / 255, blue: 221 / 255)
        }
        return isSelected ? AppColor.green.opacity(0.82) : Color(red: 229 / 255, green: 232 / 255, blue: 235 / 255)
    }

    private var borderColor: Color {
        isSelected && !metric.isDisabled ? AppColor.green.opacity(0.45) : Color(red: 235 / 255, green: 238 / 255, blue: 239 / 255)
    }

    private var titleColor: Color {
        metric.isDisabled ? AppColor.color414141.opacity(0.55) : AppColor.color414141
    }
}

struct ChartView: View {
    let points: [Double]
    let rangeText: String
    let title: String

    private var normalizedPoints: [Double] {
        points.isEmpty ? [0] : points
    }

    private var yAxisLabel: String {
        title.replacingOccurrences(of: "_", with: " ")
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(rangeText)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(Color.blue)

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColor.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            GeometryReader { proxy in
                let chartHeight = proxy.size.height - 36

                HStack(spacing: 8) {
                    Text(yAxisLabel)
                        .font(AppFont.body(size: 11))
                        .foregroundColor(AppColor.color414141.opacity(0.8))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 24)

                    ZStack(alignment: .bottomLeading) {
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(0.75))
                                .frame(height: 1)
                        }

                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.black.opacity(0.75))
                                .frame(width: 1)
                            Spacer()
                        }

                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .fill(Color(red: 231 / 255, green: 238 / 255, blue: 232 / 255))
                            .padding(.leading, 1)
                            .padding(.bottom, 1)

                        SparklineShape(points: normalizedPoints, closes: true)
                            .fill(
                                LinearGradient(
                                    colors: [AppColor.green.opacity(0.22), AppColor.green.opacity(0.06)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        SparklineShape(points: normalizedPoints)
                            .stroke(AppColor.green.opacity(0.72), lineWidth: 2)

                        HStack {
                            Text("0")
                                .font(AppFont.body(size: 11))
                                .foregroundColor(AppColor.color414141.opacity(0.72))
                                .offset(x: -14, y: 0)
                            Spacer()
                        }
                        .padding(.bottom, max(8, chartHeight * 0.48))
                    }
                }
            }
            .frame(height: 220)

            HStack {
                ForEach(Array(axisLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(AppFont.body(size: 11))
                        .foregroundColor(AppColor.color414141.opacity(0.82))
                        .frame(maxWidth: .infinity)
                }
            }

            Text("Date")
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundColor(AppColor.color414141.opacity(0.78))
        }
        .frame(maxWidth: .infinity)
    }

    private var axisLabels: [String] {
        switch normalizedPoints.count {
        case 0...2:
            return ["", "", "", ""]
        case 3...7:
            return ["1", "2", "3", "4"]
        case 8...31:
            return ["W1", "W2", "W3", "W4"]
        case 32...90:
            return ["M1", "M2", "M3", "M4"]
        case 91...366:
            return ["Q1", "Q2", "Q3", "Q4"]
        default:
            return ["Y1", "Y2", "Y3", "Y4"]
        }
    }
}

private struct SparklineShape: Shape {
    let points: [Double]
    var closes: Bool = false

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else {
            return Path { path in
                let midY = rect.height * 0.62
                path.move(to: CGPoint(x: 0, y: midY))
                path.addLine(to: CGPoint(x: rect.width, y: midY))
                if closes {
                    path.addLine(to: CGPoint(x: rect.width, y: rect.height))
                    path.addLine(to: CGPoint(x: 0, y: rect.height))
                    path.closeSubpath()
                }
            }
        }

        let minValue = points.min() ?? 0
        let maxValue = points.max() ?? 1
        let verticalScale = maxValue - minValue == 0 ? 1 : maxValue - minValue
        let step = rect.width / CGFloat(max(points.count - 1, 1))

        return Path { path in
            for index in points.indices {
                let x = CGFloat(index) * step
                let normalized = (points[index] - minValue) / verticalScale
                let y = rect.height * (1 - normalized * 0.88)

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

struct RangeSelector: View {
    let ranges: [String]
    let selectedRange: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Zoom")
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundColor(AppColor.color414141.opacity(0.8))
                .padding(.trailing, 2)

            ForEach(ranges, id: \.self) { range in
                Button(action: { onSelect(range) }) {
                    Text(range.lowercased() == "all" ? "All" : range.lowercased())
                        .font(AppFont.body(size: 12, weight: range == selectedRange ? .semibold : .medium))
                        .foregroundColor(range == selectedRange ? AppColor.black.opacity(0.9) : AppColor.color414141.opacity(0.86))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(range == selectedRange ? Color(red: 217 / 255, green: 223 / 255, blue: 1) : Color(red: 245 / 255, green: 246 / 255, blue: 247 / 255))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MetricsToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.18)) {
                configuration.isOn.toggle()
            }
        }) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(configuration.isOn ? AppColor.green.opacity(0.7) : Color(red: 232 / 255, green: 235 / 255, blue: 232 / 255))
                .frame(width: 40, height: 24)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .padding(3)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                }
        }
        .buttonStyle(.plain)
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
