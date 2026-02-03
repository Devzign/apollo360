//
//  CaregiversViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation
import Combine

@MainActor
final class CaregiversViewModel: ObservableObject {
    @Published private(set) var contacts: ContactsResponse?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isAddingCaregiver: Bool = false
    @Published private(set) var isAddingProvider: Bool = false
    @Published private(set) var errorMessage: String?

    private let session: SessionManager
    private let service: ContactsAPIService

    init(session: SessionManager, service: ContactsAPIService = .shared) {
        self.session = session
        self.service = service
        loadContacts()
    }

    var caregivers: [CaregiverContact] {
        contacts?.caregivers ?? []
    }

    var providers: [HealthcareProviderContact] {
        contacts?.healthcareProviders ?? []
    }

    var accessLevel: String {
        guard let level = contacts?.apolloAccess else { return "Unknown" }
        return "Apollo Access: \(level)"
    }

    func loadContacts(force: Bool = false) {
        guard !isLoading else { return }
        guard force || contacts == nil else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchContacts(bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.contacts = response
            case .failure(let error):
                self.errorMessage = Self.prettyMessage(for: error)
            }
        }
    }

    func addCaregiver(firstName: String, lastName: String, phone: String, email: String) {
        guard !isAddingCaregiver else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isAddingCaregiver = true
        errorMessage = nil

        let payload = CaregiverInput(firstName: firstName, lastName: lastName, phone: phone, email: email)

        service.addCaregiver(bearerToken: token, payload: payload) { [weak self] result in
            guard let self else { return }
            self.isAddingCaregiver = false
            switch result {
            case .success:
                self.loadContacts(force: true)
            case .failure(let error):
                self.errorMessage = Self.prettyMessage(for: error)
            }
        }
    }

    func addProvider(name: String, email: String, fax: String, organization: String, address: String, phone: String) {
        guard !isAddingProvider else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isAddingProvider = true
        errorMessage = nil

        let payload = HealthcareProviderInput(
            name: name,
            email: email,
            faxNumber: fax,
            organization: organization,
            address: address,
            phone: phone
        )

        service.addHealthcareProvider(bearerToken: token, payload: payload) { [weak self] result in
            guard let self else { return }
            self.isAddingProvider = false
            switch result {
            case .success:
                self.loadContacts(force: true)
            case .failure(let error):
                self.errorMessage = Self.prettyMessage(for: error)
            }
        }
    }

    func deleteCaregiver(_ key: String) {
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }
        isLoading = true
        errorMessage = nil
        service.deleteContact(key, type: .caregiver, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                var updated = self.contacts
                updated?.caregivers.removeAll(where: { $0.key == key })
                self.contacts = updated
            case .failure(let error):
                self.errorMessage = Self.prettyMessage(for: error)
            }
        }
    }

    func deleteProvider(_ key: String) {
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }
        isLoading = true
        errorMessage = nil
        service.deleteContact(key, type: .healthcareProvider, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                var updated = self.contacts
                updated?.healthcareProviders.removeAll(where: { $0.key == key })
                self.contacts = updated
            case .failure(let error):
                self.errorMessage = Self.prettyMessage(for: error)
            }
        }
    }

    func consentURL(for provider: HealthcareProviderContact) -> URL? {
        ContactsAPIService.shared.consentFormURL(
            for: provider.key,
            type: "pdf",
            formType: "outbound",
            contactType: "healthcare-provider"
        )
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
