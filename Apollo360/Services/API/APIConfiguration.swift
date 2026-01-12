import Foundation

/// Defines the set of supported environments when calling Apollo360 APIs.
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

/// Provides easy access to the current environment the app is targeting.
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

/// Consolidates endpoint paths so the API layer remains readable.
enum APIEndpoint {
    static let patientLogin = "v1/auth/patient-login"
    static let verifyOTP = "v1/auth/verify-otp"
    static let passwordLogin = "v1/auth/login"
    static func dashboardInsights(for patientId: String) -> String {
        "dashboard/insights/\(patientId)"
    }
    static func wellnessOverview(for patientId: String, mode: WellnessMode) -> String {
        "dashboard/wellness-overview/\(patientId)?mode=\(mode.rawValue.lowercased())"
    }
    static func apolloInsights(for patientId: String) -> String {
        "dashboard/apollo-insights/\(patientId)"
    }
    static func cardiometabolicMetrics(for patientId: String) -> String {
        "dashboard/cardiometabolic-metrics/\(patientId)"
    }
    static func activities(for patientId: String) -> String {
        "dashboard/activities/\(patientId)"
    }
}
