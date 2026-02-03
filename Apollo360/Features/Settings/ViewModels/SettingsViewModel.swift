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
    case forms
    case contact
    case creditCard
    case team
    case caregivers
    case notifications
    case profile
    case logout
}

struct SettingItem: Identifiable {
    let id = UUID()
    let title: String
    let kind: SettingKind
}

struct SettingSection: Identifiable {
    let id = UUID()
    let title: String?
    let items: [SettingItem]
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var sections: [SettingSection] = []
    @Published private(set) var isLoadingLegal: Bool = false
    @Published private(set) var isLoadingTeam: Bool = false
    @Published var errorMessage: String?

    @Published private(set) var termsHTML: String?
    @Published private(set) var privacyHTML: String?
    @Published private(set) var teamHTML: String?

    private let session: SessionManager
    private let service: LegalAPIService
    private let teamService: TeamAPIService

    init(
        session: SessionManager,
        service: LegalAPIService = .shared,
        teamService: TeamAPIService = .shared
    ) {
        self.session = session
        self.service = service
        self.teamService = teamService
        self.sections = Self.buildSections()
        loadLegalContent()
        loadTeamContent()
    }

    func refreshLegal() {
        loadLegalContent(force: true)
    }

    func refreshTeam() {
        loadTeamContent(force: true)
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
        case .team:
            return teamHTML
        default:
            return nil
        }
    }

    private func loadTeamContent(force: Bool = false) {
        guard !isLoadingTeam else { return }
        guard force || teamHTML == nil else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isLoadingTeam = true
        teamService.fetchTeamPage(bearerToken: token) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoadingTeam = false
                switch result {
                case .success(let html):
                    self.teamHTML = html
                case .failure(let error):
                    self.errorMessage = Self.prettyMessage(for: error)
                }
            }
        }
    }

    private static func buildSections() -> [SettingSection] {
        let settingsItems: [SettingItem] = [
            SettingItem(title: "Privacy policy", kind: .privacy),
            SettingItem(title: "Forms", kind: .forms),
            SettingItem(title: "Terms of Use", kind: .terms),
            SettingItem(title: "Contact Us", kind: .contact),
            SettingItem(title: "Billing", kind: .billing),
            SettingItem(title: "My Credit Card", kind: .creditCard),
            SettingItem(title: "Team", kind: .team),
            SettingItem(title: "My Caregivers, Doctors & Health Facilities", kind: .caregivers),
            SettingItem(title: "Notification Settings", kind: .notifications),
        ]

        let accountItems: [SettingItem] = [
            SettingItem(title: "Profile Settings", kind: .profile),
            SettingItem(title: "Logout", kind: .logout)
        ]

        return [
            SettingSection(title: "Settings", items: settingsItems),
            SettingSection(title: "Account", items: accountItems)
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

    func logout() {
        session.clearSession()
    }
}

extension SettingKind {
    var fallbackDetails: String {
        switch self {
        case .terms:
            return "Terms of use are currently unavailable. Please try again later."
        case .privacy:
            return "Privacy policy is currently unavailable. Please try again later."
        case .billing:
            return "Billing data unavailable. Please try again later."
        case .staticItem:
            return """
            By assigning benefits, you permit Apollo360 to submit claims directly to your insurer and receive payment on your behalf. The release also allows sharing of pertinent records with specialists and care partners strictly for treatment, payment, and healthcare operations.
            """
        case .forms:
            return "Forms are coming soon. Please check back later."
        case .contact:
            return "Contact details and availability are currently unavailable."
        case .creditCard:
            return "We are working to support saved credit card management."
        case .team:
            return "Team information is still loading. Please try again shortly."
        case .caregivers:
            return "Your caregivers, doctors, and facilities will appear here once configured."
        case .notifications:
            return "Control the alerts you receive from Apollo360."
        case .profile:
            return "Update your name, DOB, and contact details from this screen."
        case .logout:
            return "Logging out clears your session and requires signing back in."
        }
    }
}
