//
//  HomeNewResponseModels.swift
//  Apollo360
//

import Foundation

struct DashboardSummaryAPIResponse: Decodable {
    let success: Bool
    let data: DashboardSummaryPayload
}

struct DashboardSummaryPayload: Decodable {
    let patientProfile: DashboardPatientProfile
    let pendingAssessmentCount: Int
    let mainHealthGoal: String
    let gauges: DashboardSummaryGauges
    let notifications: [DashboardNotificationItem]
    let recentSymptoms: [DashboardRecentSymptom]

    private enum CodingKeys: String, CodingKey {
        case patientProfile, pendingAssessmentCount, mainHealthGoal, gauges, notifications, recentSymptoms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patientProfile = try container.decodeIfPresent(DashboardPatientProfile.self, forKey: .patientProfile)
            ?? DashboardPatientProfile(firstName: "", lastName: "", greeting: "Hello,", isCaregiver: false)
        pendingAssessmentCount = try container.decodeIfPresent(Int.self, forKey: .pendingAssessmentCount) ?? 0
        mainHealthGoal = try container.decodeIfPresent(String.self, forKey: .mainHealthGoal) ?? ""
        gauges = try container.decodeIfPresent(DashboardSummaryGauges.self, forKey: .gauges)
            ?? DashboardSummaryGauges(
                nutrition: DashboardGauge.empty,
                behavior: DashboardGauge.empty,
                fitness: DashboardGauge.empty
            )
        notifications = try container.decodeIfPresent([DashboardNotificationItem].self, forKey: .notifications) ?? []
        recentSymptoms = try container.decodeIfPresent([DashboardRecentSymptom].self, forKey: .recentSymptoms) ?? []
    }
}

struct DashboardPatientProfile: Decodable {
    let firstName: String
    let lastName: String
    let greeting: String
    let isCaregiver: Bool

    var fullName: String {
        let combined = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return combined.isEmpty ? "User" : combined
    }
}

struct DashboardSummaryGauges: Decodable {
    let nutrition: DashboardGauge
    let behavior: DashboardGauge
    let fitness: DashboardGauge

    private enum CodingKeys: String, CodingKey {
        case nutrition, behavior, fitness
    }

    init(nutrition: DashboardGauge, behavior: DashboardGauge, fitness: DashboardGauge) {
        self.nutrition = nutrition
        self.behavior = behavior
        self.fitness = fitness
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nutrition = try container.decodeIfPresent(DashboardGauge.self, forKey: .nutrition) ?? .empty
        behavior = try container.decodeIfPresent(DashboardGauge.self, forKey: .behavior) ?? .empty
        fitness = try container.decodeIfPresent(DashboardGauge.self, forKey: .fitness) ?? .empty
    }
}

struct DashboardGauge: Decodable {
    let metricValue: Double
    let units: String
    let targetValue: Double
    let targetDescription: String
    let statusColor: String
    let lastUpdated: String?
    let range: DashboardGaugeRange

    static let empty = DashboardGauge(
        metricValue: 0,
        units: "",
        targetValue: 0,
        targetDescription: "",
        statusColor: "DBCC5C",
        lastUpdated: nil,
        range: DashboardGaugeRange(min: 0, low: 0, high: 0, max: 0)
    )

    private enum CodingKeys: String, CodingKey {
        case metricValue, units, targetValue, targetDescription, statusColor, lastUpdated, range
    }

    init(metricValue: Double, units: String, targetValue: Double, targetDescription: String, statusColor: String, lastUpdated: String?, range: DashboardGaugeRange) {
        self.metricValue = metricValue
        self.units = units
        self.targetValue = targetValue
        self.targetDescription = targetDescription
        self.statusColor = statusColor
        self.lastUpdated = lastUpdated
        self.range = range
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        metricValue = try container.decodeIfPresent(Double.self, forKey: .metricValue) ?? 0
        units = try container.decodeIfPresent(String.self, forKey: .units) ?? ""
        targetValue = try container.decodeIfPresent(Double.self, forKey: .targetValue) ?? 0
        targetDescription = try container.decodeIfPresent(String.self, forKey: .targetDescription) ?? ""
        statusColor = try container.decodeIfPresent(String.self, forKey: .statusColor) ?? "DBCC5C"
        lastUpdated = try container.decodeIfPresent(String.self, forKey: .lastUpdated)
        range = try container.decodeIfPresent(DashboardGaugeRange.self, forKey: .range) ?? DashboardGaugeRange(min: 0, low: 0, high: 0, max: 0)
    }
}

struct DashboardGaugeRange: Decodable {
    let min: Double
    let low: Double
    let high: Double
    let max: Double

    init(min: Double, low: Double, high: Double, max: Double) {
        self.min = min
        self.low = low
        self.high = high
        self.max = max
    }
}

struct DashboardNotificationItem: Decodable {
    let id: String?
}

struct DashboardRecentSymptom: Decodable {
    let symptoms: String
    let createdAt: String
}

struct DashboardActivityPlansAPIResponse: Decodable {
    let success: Bool
    let data: DashboardActivityPlansPayload
}

struct DashboardActivityPlansPayload: Decodable {
    let nutrition: [DashboardPlanItem]
    let behavior: [DashboardPlanItem]
    let fitness: [DashboardPlanItem]

    private enum CodingKeys: String, CodingKey {
        case nutrition, behavior, fitness
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nutrition = try container.decodeIfPresent([DashboardPlanItem].self, forKey: .nutrition) ?? []
        behavior = try container.decodeIfPresent([DashboardPlanItem].self, forKey: .behavior) ?? []
        fitness = try container.decodeIfPresent([DashboardPlanItem].self, forKey: .fitness) ?? []
    }
}

struct DashboardPlanItem: Decodable, Identifiable {
    let entryId: Int
    let planItem: String
    let patientMessage: String
    let dateCreated: String
    let daysAgo: String
    let author: String?
    let authorImageUrl: String?
    let relatedContent: [DashboardRelatedContent]

    var id: Int { entryId }

    private enum CodingKeys: String, CodingKey {
        case entryId, planItem, patientMessage, dateCreated, daysAgo, author, authorImageUrl, relatedContent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entryId = try container.decodeIfPresent(Int.self, forKey: .entryId) ?? 0
        planItem = try container.decodeIfPresent(String.self, forKey: .planItem) ?? ""
        patientMessage = try container.decodeIfPresent(String.self, forKey: .patientMessage) ?? ""
        dateCreated = try container.decodeIfPresent(String.self, forKey: .dateCreated) ?? ""
        daysAgo = try container.decodeIfPresent(String.self, forKey: .daysAgo) ?? "0"
        author = try container.decodeIfPresent(String.self, forKey: .author)
        authorImageUrl = try container.decodeIfPresent(String.self, forKey: .authorImageUrl)
        relatedContent = try container.decodeIfPresent([DashboardRelatedContent].self, forKey: .relatedContent) ?? []
    }
}

struct DashboardRelatedContent: Decodable, Identifiable {
    let entryId: Int
    let title: String
    let urlTitle: String
    let displayImage: String?
    let viewingTime: String?
    let videoURL: String?
    let thumbnailURL: String?
    let isSaved: Bool
    let isRecentlyVisited: Bool
    let tags: String?

    var id: Int { entryId }

    private enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case title
        case urlTitle = "url_title"
        case displayImage = "display_image"
        case viewingTime = "viewing_time"
        case videoURL = "video_url"
        case thumbnailURL = "thumbnail_url"
        case isSaved = "is_saved"
        case isRecentlyVisited = "is_recently_visited"
        case tags
    }
}

struct DashboardMetricsLookupAPIResponse: Decodable {
    let success: Bool
    let data: [DashboardLookupCategory]
}

struct DashboardLookupCategory: Decodable, Identifiable {
    let category: String
    let metrics: [DashboardLookupMetric]

    var id: String { category }
}

struct DashboardLookupMetric: Decodable, Identifiable {
    let id: Int
    let type: String
    let unit: String
}
