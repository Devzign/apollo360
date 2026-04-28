//
//  DashboardMetricsResponse.swift
//  Apollo360
//

import Foundation

struct DashboardMetricsAPIResponse: Decodable {
    let success: Bool
    let data: DashboardMetricsPayload
}

struct DashboardMetricsPayload: Decodable {
    let metrics: [DashboardMetricPayload]
    let flaggedConcerns: [DashboardFlaggedConcernPayload]
}

struct DashboardMetricPayload: Decodable {
    let metricId: Int
    let metricField: String
    let description: String
    let factor: Double?
    let defaultUnit: String?
    let optimalFrom: Double?
    let optimalThru: Double?
    let latestValue: Double?
    let averageValue: Double?
    let percentageChange: Double?
    let source: String?
    let lastSyncDate: String?
    let syncStatus: String?
    let isFlagged: Bool
}

struct DashboardFlaggedConcernPayload: Decodable {
    let metricField: String
    let description: String
}
