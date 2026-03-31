//
//  CreditCard.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation
import Combine

struct CreditCard: Identifiable, Decodable {
    let id: String
    let customerPaymentProfileId: String
    let cardNumber: String?
    let cardBrand: String?
    let expMonth: String?
    let expYear: String?
    let rawExpirationDate: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case customerPaymentProfileId
        case cardNumber
        case cardBrand
        case expMonth
        case expYear
        case expirationDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func decodeString(_ key: CodingKeys) -> String? {
            if let value = try? container.decode(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            if let value = try? container.decode(Int.self, forKey: key) {
                return String(value)
            }
            return nil
        }

        let profileId = decodeString(.customerPaymentProfileId)
        id = decodeString(.id) ?? profileId ?? UUID().uuidString
        customerPaymentProfileId = profileId ?? id
        cardNumber = decodeString(.cardNumber)
        cardBrand = decodeString(.cardBrand)

        let rawMonth = decodeString(.expMonth)
        let rawYear = decodeString(.expYear)
        if rawMonth != nil || rawYear != nil {
            expMonth = rawMonth
            expYear = rawYear
        } else {
            let expiry = decodeString(.expirationDate) ?? ""
            rawExpirationDate = expiry.isEmpty ? nil : expiry
            let parts = expiry.split(separator: "/", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                expMonth = parts[0]
                expYear = parts[1]
            } else {
                expMonth = nil
                expYear = nil
            }
            return
        }
        rawExpirationDate = nil
    }

    var maskedNumber: String {
        guard let raw = cardNumber else { return "•••• •••• •••• ••••" }
        let normalized = raw.filter { $0.isNumber }
        if normalized.count >= 4 {
            let suffix = normalized.suffix(4)
            return "•••• •••• •••• \(suffix)"
        }
        return String(repeating: "•", count: max(4, normalized.count))
    }

    var expiryDisplay: String {
        if let rawExpirationDate, !rawExpirationDate.isEmpty {
            return rawExpirationDate
        }
        switch (expMonth, expYear) {
        case let (.some(month), .some(year)):
            return "\(month)/\(year)"
        case let (.some(month), .none):
            return "\(month)"
        case let (.none, .some(year)):
            return "••/\(year)"
        default:
            return "MM/YY"
        }
    }
}

struct CreditCardListResponse: Decodable {
    let cards: [CreditCard]

    private enum CodingKeys: String, CodingKey {
        case cards
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let items = try? container.decode([CreditCard].self, forKey: .cards) {
            cards = items
            return
        }
        cards = (try? container.decode([CreditCard].self, forKey: .data)) ?? []
    }
}
