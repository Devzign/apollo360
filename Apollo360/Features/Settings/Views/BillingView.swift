//
//  BillingView.swift
//  Apollo360
//
//  Created by Amit Sinha on 02/02/26.
//

import SwiftUI

struct BillingView: View {
    @StateObject private var viewModel: BillingViewModel

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: BillingViewModel(session: session))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColor.white, AppColor.green.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    totalsCard
                    invoicesSection
                    spacerBottom
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Billing Statement")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(.top, 12)
            }
        }
        .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Button("Retry", action: viewModel.load)
            Button("Dismiss", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Your Total Balance")
                .font(AppFont.body(size: 15, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
            Text(viewModel.formatted(viewModel.displayTotals.total_io_patient_balance))
                .font(AppFont.display(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Total Billed Amount")
                    .font(AppFont.body(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.black)
                Spacer()
                Text(viewModel.formatted(viewModel.displayTotals.total_billed))
                    .font(AppFont.body(size: 17, weight: .bold))
                    .foregroundStyle(AppColor.green)
            }
            .padding(.bottom, 6)

            billRow(title: "Billed", value: viewModel.displayTotals.total_ptm)
            billRow(title: "Adjust", value: viewModel.displayTotals.total_adjustment)
            billRow(title: "Insurance Paid", value: viewModel.displayTotals.total_carrier_paid)
            billRow(title: "Co-insurance", value: viewModel.displayTotals.total_coins)
            billRow(title: "Co-pay", value: viewModel.displayTotals.total_copay)
            billRow(title: "Deductible", value: viewModel.displayTotals.total_deduct)
            billRow(title: "Prev Payment", value: viewModel.displayTotals.total_patient_paid)
            billRow(title: "Write-off", value: viewModel.displayTotals.total_writeoff)

            Divider()
                .padding(.vertical, 4)

            HStack {
                Text("Your Balance")
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.black)
                Spacer()
                Text(viewModel.formatted(viewModel.displayTotals.total_io_patient_balance))
                    .font(AppFont.body(size: 18, weight: .bold))
                    .foregroundStyle(AppColor.green)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 6)
    }

    private var invoicesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Invoices")
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.black.opacity(0.8))

            Text("No invoices available.")
                .font(AppFont.body(size: 14))
                .foregroundStyle(AppColor.grey)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
    }

    private var spacerBottom: some View {
        Color.clear.frame(height: 40)
    }

    private func billRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body(size: 15, weight: .medium))
                .foregroundStyle(AppColor.black)
            Spacer()
            Text(viewModel.formatted(value))
                .font(AppFont.body(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.black)
        }
    }
}

#Preview {
    NavigationStack {
        BillingView(session: SessionManager())
    }
}
