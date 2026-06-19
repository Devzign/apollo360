import SwiftUI

struct DoctorMeDashboard: View {
    let doctorMetrics: [DashboardMetricCardModel]
    let myMetrics: [DashboardMetricCardModel]
    let isLoading: Bool
    let errorMessage: String?
    let session: SessionManager
    let onSelectMetrics: () -> Void
    let onFixSync: () -> Void

    @State private var selectedMetric: DashboardMetricCardModel?
    @State private var instructionSource: SyncInstructionSource?
    @State private var showsAllMyMetrics = false

    private let canvas = Color(red: 246 / 255, green: 255 / 255, blue: 249 / 255)

    private var syncingCount: Int {
        (doctorMetrics + myMetrics).filter { isOlderThan48Hours($0.lastSyncDateRaw) }.count
    }

    private var visibleMyMetrics: [DashboardMetricCardModel] {
        showsAllMyMetrics ? myMetrics : Array(myMetrics.prefix(2))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 12) {
                syncBanner

                if isLoading && doctorMetrics.isEmpty && myMetrics.isEmpty {
                    ProgressView("Loading dashboard metrics...")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                }

                if let errorMessage, !errorMessage.isEmpty,
                   doctorMetrics.isEmpty && myMetrics.isEmpty {
                    Text(errorMessage)
                        .font(AppFont.body(size: 13, weight: .medium))
                        .foregroundColor(AppColor.red)
                        .padding(.vertical, 12)
                }

                doctorSection
                mySection

                Color.clear.frame(height: 130)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(canvas.ignoresSafeArea())
        .sheet(item: $selectedMetric) { metric in
            DashboardMetricDetailSheet(metric: metric, session: session)
                .presentationDetents([.height(530)])
                .presentationDragIndicator(.hidden)
                .modifier(PresentationCornerRadiusModifier(radius: 28))
        }
        .sheet(item: $instructionSource) { source in
            SyncInstructionSheet(source: source.value, metricTitle: source.metricTitle)
                .presentationDetents([.height(600)])
                .presentationDragIndicator(.hidden)
                .modifier(PresentationCornerRadiusModifier(radius: 28))
        }
    }

    private var syncBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 255 / 255, green: 225 / 255, blue: 169 / 255))
                    .frame(width: 34, height: 34)
                Image(systemName: "bolt.slash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 84 / 255, green: 63 / 255, blue: 34 / 255))
            }

            Text(syncingCount == 1 ? "1 metric needs syncing" : "\(syncingCount) metrics need syncing")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 70 / 255, green: 59 / 255, blue: 43 / 255))

            Spacer()

            Button("Fix", action: onFixSync)
                .font(AppFont.body(size: 11, weight: .bold))
                .foregroundColor(Color(red: 70 / 255, green: 59 / 255, blue: 43 / 255))
                .padding(.horizontal, 11)
                .frame(height: 24)
                .background(Capsule().fill(Color.black.opacity(0.08)))
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 255 / 255, green: 248 / 255, blue: 222 / 255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 246 / 255, green: 193 / 255, blue: 101 / 255), lineWidth: 1)
        )
    }

    private var doctorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if doctorMetrics.indices.contains(0) {
                heroCard(doctorMetrics[0], style: .primaryHero)
            }
            if doctorMetrics.indices.contains(1) {
                heroCard(doctorMetrics[1], style: .secondaryHero)
            }

            sectionTitle("Doctor Prescribed", count: max(doctorMetrics.count - 2, 0), icon: "stethoscope")
                .padding(.top, 8)

            metricList(Array(doctorMetrics.dropFirst(2)))
        }
    }

    private var mySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onSelectMetrics) {
                sectionTitle("Added By Me", count: myMetrics.count, icon: "person")
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            metricList(visibleMyMetrics)

            if myMetrics.count > 2 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showsAllMyMetrics.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(showsAllMyMetrics ? "Show less" : "Show more")
                        Image(systemName: showsAllMyMetrics ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(AppFont.body(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0 / 255, green: 154 / 255, blue: 102 / 255))
                    .padding(.horizontal, 18)
                    .frame(height: 36)
                    .background(Capsule().fill(Color(red: 237 / 255, green: 248 / 255, blue: 242 / 255)))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func heroCard(_ metric: DashboardMetricCardModel, style: HeroMetricCard.Style) -> some View {
        HeroMetricCard(metric: metric, style: style) {
            selectedMetric = metric
        } onInstructionTap: {
            instructionSource = SyncInstructionSource(value: metric.sourceText, metricTitle: metric.title)
        }
    }

    @ViewBuilder
    private func metricList(_ metrics: [DashboardMetricCardModel]) -> some View {
        if metrics.isEmpty {
            Text("No metrics available.")
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundColor(AppColor.grey)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
        } else {
            ForEach(metrics) { metric in
                DoctorMeMetricCard(metric: metric) {
                    selectedMetric = metric
                } onInstructionTap: {
                    instructionSource = SyncInstructionSource(value: metric.sourceText, metricTitle: metric.title)
                }
            }
        }
    }

    private func sectionTitle(_ title: String, count: Int, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0 / 255, green: 171 / 255, blue: 111 / 255))
                .frame(width: 18)
            Text(title)
                .font(AppFont.body(size: 16, weight: .bold))
                .foregroundColor(Color(red: 22 / 255, green: 31 / 255, blue: 37 / 255))
            Text("(\(count))")
                .font(AppFont.body(size: 14, weight: .medium))
                .foregroundColor(AppColor.grey)
        }
    }
}
