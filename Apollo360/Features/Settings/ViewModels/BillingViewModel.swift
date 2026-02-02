//
//  BillingViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 02/02/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class BillingViewModel: ObservableObject {
    @Published private(set) var totals: BillingTotals?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let session: SessionManager
    private let service: BillingAPIService

    init(session: SessionManager, service: BillingAPIService = .shared) {
        self.session = session
        self.service = service
        load()
    }

    func load() {
        guard !isLoading else { return }
        guard let token = session.accessToken, let patientId = session.patientId else {
            errorMessage = "You're not signed in."
            return
        }
        isLoading = true
        errorMessage = nil

        service.fetchBilling(for: patientId, bearerToken: token) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let data):
                self.totals = data.totals
            case .failure(let error):
                self.errorMessage = BillingViewModel.prettyMessage(for: error)
                self.totals = nil
            }
            self.isLoading = false
        }
    }

    var displayTotals: BillingTotals {
        totals ?? BillingTotals(
            total_ptm: 0, total_patient_ptm_paid: 0, total_patient_paid: 0,
            total_io_patient_balance: 0, total_allowed: 0, total_carrier_paid: 0,
            total_coins: 0, total_copay: 0, total_deduct: 0, total_writeoff: 0,
            total_billed: 0, total_adjustment: 0
        )
    }

    private static func prettyMessage(for error: APIError) -> String {
        switch error {
        case .invalidURL: return "Invalid URL."
        case .encodingFailed(let err), .decodingFailed(let err): return "Parsing failed: \(err.localizedDescription)"
        case .requestFailed(let err): return err.localizedDescription
        case .invalidResponse: return "Invalid server response."
        case .serverError(let code, _): return "Server error (\(code)). Please try again."
        case .noData: return "No data received."
        }
    }

    func formatted(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
