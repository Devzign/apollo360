//
//  APIConfiguration.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

enum APIEnvironment: String, CaseIterable {
    case development
    case production

    var baseURLString: String {
        switch self {
        case .development:
            return "https://backend.pp-a360.com/api"
        case .production:
            return "https://backend.pp-a360.com/api"
        }
    }

    var baseURL: URL {
        URL(string: baseURLString)!
    }
}

enum APIConfiguration {
    static var currentEnvironment: APIEnvironment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()

    static var baseURL: URL {
        currentEnvironment.baseURL
    }
}

enum APIEndpoint {
    static let patientLogin = "v1/auth/patient-login"
    static let verifyOTP = "v1/auth/verify-otp"
    static let refreshToken = "v1/auth/refresh"
    static let patientFaceID = "patient-faceId"
    static let passwordLogin = "v1/auth/login"
    static let logout = "v1/auth/logout"
    static let patientForms = "v1/patient-forms"
    static let termsOfUse = "v1/terms-of-use"
    static let privacyPolicy = "v1/privacy-policy"
    static let profile = "v1/profile"
    static let profilePicture = "v1/profile/picture"
    static let appointments = "v1/appointments"
    static func articles(type: String,
                         search: String,
                         filter: String,
                         page: Int,
                         limit: Int) -> String {
        let encType = type.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? type
        let encSearch = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search
        let encFilter = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filter
        return "v1/articles?type=\(encType)&search=\(encSearch)&filter=\(encFilter)&page=\(page)&limit=\(limit)"
    }
    static func articleDetails(id: Int) -> String {
        "v1/articles/\(id)"
    }
    static func articleSave(id: Int) -> String {
        "v1/articles/\(id)/save"
    }
    static func rpmFolderMetrics(for patientId: String) -> String {
        "v1/rpm-folders/metrics/\(patientId)"
    }
    static func userMetric(metricField: String, patientId: String, selectedRange: String) -> String {
        "v1/usermetric/\(metricField)/\(patientId)/\(selectedRange)"
    }
    static func labAvailableMetricList(for patientId: String) -> String {
        "v1/lab-available-metric-list/\(patientId)"
    }
    static func metricDescription(metricField: String, patientId: String, memberId: String) -> String {
        "v1/metric-description/\(metricField)/\(patientId)/\(memberId)"
    }
    static func compareUserMetric(metricId: String,
                                  compMetricId: String,
                                  patientId: String,
                                  memberId: String,
                                  metricType: String) -> String {
        "v1/compare-user-metric/\(metricId)/\(compMetricId)/\(patientId)/\(memberId)/\(metricType)"
    }
    static func checkMetric(metricId: String,
                            patientId: String,
                            memberId: String) -> String {
        "v1/check-metric/\(metricId)/\(patientId)/\(memberId)"
    }
    static func showAllRPMMetrics(for patientId: String) -> String {
        "v1/show-all-rpm-metrics/\(patientId)"
    }
    static func saveUserMetrics(patientId: String, metricGroupId: String) -> String {
        "v1/save-user-metrics/\(patientId)/\(metricGroupId)"
    }
    static func billingCards(for patientId: String) -> String {
        "v1/billing/cards/\(patientId)"
    }
    static func billingCard(for patientId: String, cardId: String) -> String {
        "v1/billing/cards/\(patientId)/\(cardId)"
    }
    static func billingInfo(for patientId: String) -> String {
        "v1/get-billing-info/\(patientId)"
    }
    static func dashboardInsights(for patientId: String) -> String {
        "v1/dashboard/insights/\(patientId)"
    }
    static func wellnessOverview(for patientId: String, mode: WellnessMode) -> String {
        "v1/dashboard/wellness-overview/\(patientId)?mode=\(mode.rawValue.lowercased())"
    }
    static func apolloInsights(for patientId: String) -> String {
        "v1/dashboard/apollo-insights/\(patientId)"
    }
    static func cardiometabolicMetrics(for patientId: String) -> String {
        "v1/dashboard/cardiometabolic-metrics/\(patientId)"
    }
    static func activities(for patientId: String) -> String {
        "v1/dashboard/activities/\(patientId)"
    }
    static func messagesConversation(for patientId: Int, a360hId: Int) -> String {
        "v1/messages/all/\(patientId)?a360hId=\(a360hId)"
    }
    static func messagesConversation(for patientId: Int, a360hId: Int, providerMemberId: Int) -> String {
        "v1/messages/all/\(patientId)?a360hId=\(a360hId)&providerMemberId=\(providerMemberId)"
    }
    static let validicUser = "v1/validic/user"
    static let team = "v1/team"
    static let myContacts = "v1/my-contacts"
    static let myContactsCaregiver = "v1/my-contacts/caregiver"
    static let myContactsHealthcareProvider = "v1/my-contacts/healthcare-provider"
    static func myContactsContact(key: String) -> String {
        "v1/my-contacts/\(key)"
    }
    static func myContactsConsentForm(key: String, type: String, formType: String, contactType: String) -> String {
        "v1/my-contacts/\(key)/consent-form?type=\(type)&formType=\(formType)&contactType=\(contactType)"
    }

    static func providers(for patientId: Int) -> String {
        "v1/list-of-providers/\(patientId)"
    }
    static var sendMessage: String {
        "v1/messages"
    }
}
