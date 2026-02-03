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

    func addCard(cardNumber: String, month: String, year: String, cvv: String) {
        guard !isSubmitting else { return }
        guard let patientId = session.patientId, !patientId.isEmpty,
              let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let payload = CreditCardRequest(cardNumber: cardNumber,
                                        expMonth: month,
                                        expYear: year,
                                        cvv: cvv)

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
}
