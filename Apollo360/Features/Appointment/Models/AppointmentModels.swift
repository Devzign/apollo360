//
//  AppointmentModels.swift
//  Apollo360
//
//  Created by Amit Sinha on 28/01/26.
//

import SwiftUI

struct AppointmentCard: Identifiable {
    let id: UUID
    let name: String
    let role: String
    let date: String
    let time: String
    let accentColor: Color
    let callType: String?
    let isTelevisit: Bool
    let acsId: String?
    let acsToken: String?
    let acsRoomId: String?

    init(
        id: UUID = UUID(),
        name: String,
        role: String,
        date: String,
        time: String,
        accentColor: Color,
        callType: String? = nil,
        isTelevisit: Bool = false,
        acsId: String? = nil,
        acsToken: String? = nil,
        acsRoomId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.date = date
        self.time = time
        self.accentColor = accentColor
        self.callType = callType
        self.isTelevisit = isTelevisit
        self.acsId = acsId
        self.acsToken = acsToken
        self.acsRoomId = acsRoomId
    }
}
