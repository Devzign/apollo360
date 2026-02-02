//
//  BillingAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 02/02/26.
//

import Foundation

struct BillingResponse: Decodable {
    let success: Bool
    let data: BillingData
}

struct BillingData: Decodable {
    let rows: [BillingRow]
    let totals: BillingTotals
    let invoices: [BillingInvoice]
}

struct BillingRow: Decodable, Identifiable {
    var id = UUID()
    let date: String?
    let description: String?
    let amount: Double?
}

struct BillingTotals: Decodable {
    let total_ptm: Double
    let total_patient_ptm_paid: Double
    let total_patient_paid: Double
    let total_io_patient_balance: Double
    let total_allowed: Double
    let total_carrier_paid: Double
    let total_coins: Double
    let total_copay: Double
    let total_deduct: Double
    let total_writeoff: Double
    let total_billed: Double
    let total_adjustment: Double
}

struct BillingInvoice: Decodable, Identifiable {
    let id = UUID()
    let name: String?
    let url: String?
}

final class BillingAPIService {
    static let shared = BillingAPIService()
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchBilling(for patientId: String,
                      bearerToken: String,
                      completion: @escaping (Result<BillingData, APIError>) -> Void) {
        client.request(
            endpoint: APIEndpoint.billingInfo(for: patientId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"],
            responseType: BillingResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
