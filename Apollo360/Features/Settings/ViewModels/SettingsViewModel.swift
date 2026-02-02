//
//  SettingsViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 02/02/26.
//

import Foundation
import Combine

enum SettingKind: Hashable {
    case terms
    case privacy
    case billing
    case staticItem(id: String)
}

struct SettingItem: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let kind: SettingKind
    let fallbackDetails: String
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var items: [SettingItem] = []
    @Published private(set) var isLoadingLegal: Bool = false
    @Published var errorMessage: String?

    @Published private(set) var termsHTML: String?
    @Published private(set) var privacyHTML: String?

    private let session: SessionManager
    private let service: LegalAPIService

    init(session: SessionManager, service: LegalAPIService = .shared) {
        self.session = session
        self.service = service
        self.items = Self.buildItems()
        loadLegalContent()
    }

    func refreshLegal() {
        loadLegalContent(force: true)
    }

    private func loadLegalContent(force: Bool = false) {
        guard !isLoadingLegal else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isLoadingLegal = true
        errorMessage = nil

        let group = DispatchGroup()
        var fetchError: APIError?

        group.enter()
        service.fetchTermsOfUse(bearerToken: token) { [weak self] result in
            defer { group.leave() }
            guard let self else { return }
            switch result {
            case .success(let html):
                self.termsHTML = html
            case .failure(let error):
                fetchError = error
            }
        }

        group.enter()
        service.fetchPrivacyPolicy(bearerToken: token) { [weak self] result in
            defer { group.leave() }
            guard let self else { return }
            switch result {
            case .success(let html):
                self.privacyHTML = html
            case .failure(let error):
                fetchError = error
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.isLoadingLegal = false
            if let fetchError {
                self.errorMessage = Self.prettyMessage(for: fetchError)
            }
        }
    }

    func html(for kind: SettingKind) -> String? {
        switch kind {
        case .terms:
            return termsHTML
        case .privacy:
            return privacyHTML
        case .billing:
            return nil
        case .staticItem:
            return nil
        }
    }

    private static func buildItems() -> [SettingItem] {
        [
            SettingItem(
                title: "Terms, Conditions and Consent",
                summary: "Review the terms that guide care delivery, signatures, and digital consent.",
                kind: .terms,
                fallbackDetails: "Terms of use are currently unavailable. Please try again later."
            ),
            SettingItem(
                title: "Privacy",
                summary: "Understand how your personal health information is collected, used, and shared.",
                kind: .privacy,
                fallbackDetails: "Privacy policy is currently unavailable. Please try again later."
            ),
            SettingItem(
                title: "Billing Statement",
                summary: "View your total balance, billed amounts, and insurance payments.",
                kind: .billing,
                fallbackDetails: "Billing data unavailable. Please try again later."
            ),
            SettingItem(
                title: "Assignment of Benefits and Releases",
                summary: "Allow Apollo360 to bill insurance and share records for care coordination.",
                kind: .staticItem(id: "benefits"),
                fallbackDetails: """
                By assigning benefits, you permit Apollo360 to submit claims directly to your insurer and receive payment on your behalf. The release also allows sharing of pertinent records with specialists and care partners strictly for treatment, payment, and healthcare operations.
                """
            )
        ]
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
