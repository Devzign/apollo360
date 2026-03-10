//
//  CreditCardViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation
import Combine

@MainActor
final class CreditCardViewModel: ObservableObject {
    @Published private(set) var cards: [CreditCard] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSubmitting: Bool = false
    @Published private(set) var errorMessage: String?

    private let session: SessionManager
    private let service: CreditCardAPIService
    private static let cardRegex = "^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|2(?:2[2-9][0-9]{12}|[3-6][0-9]{13}|7[01][0-9]{12}|720[0-9]{12})|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\\d{3})\\d{11}|62[0-9]{14,17}|(?:508|60|65|81|82)[0-9]{13})$"
    private static let expiryRegex = "^(0[1-9]|1[0-2])\\/(\\d{2}|\\d{4})$"
    private static let cvvRegex = "^\\d{3,4}$"

    init(session: SessionManager,
         service: CreditCardAPIService = .shared) {
        self.session = session
        self.service = service
        loadCards()
    }

    func loadCards(force: Bool = false) {
        guard !isLoading else { return }
        guard force || cards.isEmpty else { return }
        guard let patientId = session.patientId, !patientId.isEmpty,
              let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchCards(patientId: patientId, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let cards):
                self.cards = cards
            case .failure(let error):
                self.errorMessage = Self.prettyMessage(for: error)
            }
        }
    }

    @discardableResult
    func addCard(cardNumber: String, month: String, year: String, cvv: String) -> Bool {
        guard !isSubmitting else { return false }
        guard let patientId = session.patientId, !patientId.isEmpty,
              let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return false
        }

        let normalizedCard = cardNumber.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        let normalizedMonth = month.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedYear = year.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCVV = cvv.trimmingCharacters(in: .whitespacesAndNewlines)
        let expiry = "\(normalizedMonth)/\(normalizedYear)"

        if !Self.matches(normalizedCard, regex: Self.cardRegex) {
            errorMessage = "Invalid card number."
            return false
        }
        if !Self.matches(expiry, regex: Self.expiryRegex) {
            errorMessage = "Invalid expiry. Use MM/YY or MM/YYYY."
            return false
        }
        if !Self.matches(normalizedCVV, regex: Self.cvvRegex) {
            errorMessage = "Invalid CVV."
            return false
        }

        isSubmitting = true
        errorMessage = nil

        let payload = CreditCardRequest(cardNumber: normalizedCard,
                                        expMonth: normalizedMonth,
                                        expYear: normalizedYear,
                                        cvv: normalizedCVV)

        service.addCard(patientId: patientId, bearerToken: token, payload: payload) { [weak self] result in
            guard let self else { return }
            self.isSubmitting = false
            switch result {
            case .success:
                self.loadCards(force: true)
            case .failure(let error):
                self.errorMessage = Self.prettyMessage(for: error)
            }
        }
        return true
    }

    func deleteCard(_ cardId: String) {
        guard let patientId = session.patientId, !patientId.isEmpty,
              let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        service.deleteCard(patientId: patientId, cardId: cardId, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                self.cards.removeAll { $0.id == cardId }
            case .failure(let error):
                self.errorMessage = Self.prettyMessage(for: error)
            }
        }
    }

    private static func prettyMessage(for error: APIError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid URL."
        case .encodingFailed(let err), .decodingFailed(let err):
            return "Parsing failed: \(err.localizedDescription)"
        case .requestFailed(let err):
            return err.localizedDescription
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let code, _):
            return "Server error (\(code)). Please try again."
        case .noData:
            return "No data received."
        }
    }

    private static func matches(_ value: String, regex: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
    }
}
