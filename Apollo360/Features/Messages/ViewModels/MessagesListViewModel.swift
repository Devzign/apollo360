//
//  MessagesListViewModel.swift
//  Apollo360
//
//  Created by Codex on 29/01/26.
//

import Foundation
import Combine

@MainActor
final class MessagesListViewModel: ObservableObject {
    @Published private(set) var providers: [MessageProvider] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let session: SessionManager
    private let service: MessageAPIService

    init(session: SessionManager,
         service: MessageAPIService = .shared) {
        self.session = session
        self.service = service
    }

    func loadProviders() {
        guard let token = session.accessToken,
              let patientId = parseInt(session.patientId) else {
            errorMessage = "Missing session or patient id."
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchProviders(patientId: patientId, token: token) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let providers):
                    self.providers = providers
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.providers = []
                }
            }
        }
    }
}

private extension MessagesListViewModel {
    func parseInt(_ value: String?) -> Int? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              let intVal = Int(trimmed) else {
            return nil
        }
        return intVal
    }
}
