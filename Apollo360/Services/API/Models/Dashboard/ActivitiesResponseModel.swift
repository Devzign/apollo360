//
//  ActivitiesResponseModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct ActivitiesAPIResponse: Decodable {
    let success: Bool
    let data: ActivitiesPayload
}

struct ActivitiesPayload: Decodable {
    let title: String
    let subtitle: String
    let weeklyChangePercent: Int
    let chart: [ActivityChartEntry]
    let summary: ActivitySummary
    let message: String
}

struct ActivityChartEntry: Decodable {
    let day: String
    let value: Int
    let isActive: Bool
}

struct ActivitySummary: Decodable {
    let avgSteps: Int
    let activeDays: Int
    let calories: Int
}
