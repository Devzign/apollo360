//
//  WellnessOverviewResponseModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct WellnessOverviewAPIResponse: Decodable {
    let success: Bool
    let data: WellnessOverviewPayload
}

struct WellnessOverviewPayload: Decodable {
    let mode: String
    let overallScore: Int
    let absolute: WellnessAbsoluteBreakdown
    let relative: WellnessRelativeBreakdown?
}

struct WellnessAbsoluteBreakdown: Decodable {
    let activity: Int
    let sleep: Int
    let heart: Int
    let nutrition: Int
}

struct WellnessRelativeBreakdown: Decodable {
    let activity: Int
    let sleep: Int
    let heart: Int
    let nutrition: Int
}
