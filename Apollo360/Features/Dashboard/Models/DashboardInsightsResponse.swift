//
//  DashboardInsightsResponse.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct DashboardInsightsResponse: Decodable {
    let success: Bool
    let data: [DashboardInsightPayload]
}

struct DashboardInsightPayload: Decodable {
    let category: String
    let title: String
    let subtitle: String
    let recommendation: String
    let iconUrl: URL?
}
