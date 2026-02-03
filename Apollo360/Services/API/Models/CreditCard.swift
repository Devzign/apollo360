//
//  CreditCard.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation

struct CreditCard: Identifiable, Decodable {
    let id: String
    let cardNumber: String?
    let cardBrand: String?
    let expMonth: String?
    let expYear: String?

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
}
