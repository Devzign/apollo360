import SwiftUI

struct BillingView: View {

    @StateObject private var viewModel: BillingViewModel

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: BillingViewModel(session: session))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {

                LinearGradient(
                    colors: [
                        AppColor.white,
                        AppColor.primary,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
                .ignoresSafeArea(edges: .top)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        headerSection

                        billingCard
                            .padding(.top, -28)
                            .frame(
                                minHeight: geo.size.height
                                    - 320
                                    + 28
                            )
                    }
                }
            }
        }
        .navigationTitle("Billing Statement")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Header
private extension BillingView {
    var headerSection: some View {
        VStack(spacing: 10) {
            Text("Your Total Balance")
                .font(AppFont.body(size: 18, weight: .medium))
                .foregroundColor(.white)

            Text(viewModel.formatted(viewModel.displayTotals.total_io_patient_balance))
                .font(AppFont.display(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
        .padding(.bottom, 70)
    }
}

// MARK: - Billing Card
private extension BillingView {

    var billingCard: some View {
        VStack(spacing: 20) {

            totalBilledPill

            billRow(title: "Billed", value: viewModel.displayTotals.total_ptm)
            billRow(title: "Adjust", value: viewModel.displayTotals.total_adjustment)
            billRow(title: "Insurance Paid", value: viewModel.displayTotals.total_carrier_paid)
            billRow(title: "Co-insurance", value: viewModel.displayTotals.total_coins)
            billRow(title: "Co-pay", value: viewModel.displayTotals.total_copay)
            billRow(title: "Deductible", value: viewModel.displayTotals.total_deduct)
            billRow(title: "Prev Payment", value: viewModel.displayTotals.total_patient_paid)
            billRow(title: "Write-off", value: viewModel.displayTotals.total_writeoff)

            Divider()
                .background(AppColor.green.opacity(0.3))

            balanceRow
        }
        .padding(20)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.clear)
                    .shadow(
                        color: .black.opacity(0.18),
                        radius: 16,
                        x: 0,
                        y: -10
                    )
                    .mask(
                        VStack(spacing: 0) {
                            Rectangle()
                                .frame(height: 80)
                            Spacer()
                        }
                    )
            }
        }
    }
}

// MARK: - Total Billed Pill
private extension BillingView {

    var totalBilledPill: some View {
        HStack {
            Text("Total Billed Amount")
                .font(AppFont.body(size: 18, weight: .semibold))
                .foregroundColor(AppColor.color414141)

            Spacer()

            Text(viewModel.formatted(viewModel.displayTotals.total_billed))
                .font(AppFont.body(size: 18, weight: .bold))
                .foregroundColor(AppColor.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColor.grey.opacity(0.12))
        )
    }
}

// MARK: - Rows
private extension BillingView {

    func billRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body(size: 18, weight: .medium))
                .foregroundColor(AppColor.color414141)

            Spacer()

            Text(viewModel.formatted(value))
                .font(AppFont.body(size: 18, weight: .semibold))
                .foregroundColor(AppColor.color414141)
        }
    }

    var balanceRow: some View {
        HStack {
            Text("Your Balance")
                .font(AppFont.body(size: 20, weight: .semibold))
                .foregroundColor(AppColor.color414141)

            Spacer()

            Text(viewModel.formatted(viewModel.displayTotals.total_io_patient_balance))
                .font(AppFont.body(size: 20, weight: .bold))
                .foregroundColor(AppColor.primary)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        BillingView(session: SessionManager())
    }
}
