//
//  Contacts.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation

struct ContactsResponse: Decodable {
    let apolloAccess: Int?
    var caregivers: [CaregiverContact]
    var healthcareProviders: [HealthcareProviderContact]
}

struct CaregiverContact: Identifiable, Decodable {
    let key: String
    let name: String
    let phone: String?
    let email: String?
    let permissions: CaregiverPermissions?
    let isSigned: Bool?

    var id: String {
        key
    }
}

struct CaregiverPermissions: Decodable {
    let home: Bool?
    let messages: Bool?
    let metrics: Bool?
    let documents: Bool?
    let appointments: Bool?
    let medicalPlan: Bool?

    private enum CodingKeys: String, CodingKey {
        case home, messages, metrics, documents, appointments
        case medicalPlan = "medical_plan"
    }
}

struct HealthcareProviderContact: Identifiable, Decodable {
    let key: String
    let name: String
    let phone: String?
    let fax: String?
    let email: String?
    let organization: String?
    let permissions: HealthcareProviderPermissions?
    let signedSend: Bool?
    let signedReceive: Bool?

    var id: String {
        key
    }
}

struct HealthcareProviderPermissions: Decodable {
    let requestRecords: Bool?
    let sendRPMNotes: Bool?
    let sendVisitNotes: Bool?
    let sendLabResults: Bool?

    private enum CodingKeys: String, CodingKey {
        case requestRecords = "request_records"
        case sendRPMNotes = "send_rpm_notes"
        case sendVisitNotes = "send_visit_notes"
        case sendLabResults = "send_lab_results"
    }
}

struct CaregiverInput: Encodable {
    let firstName: String
    let lastName: String
    let phone: String
    let email: String
}

struct HealthcareProviderInput: Encodable {
    let name: String
    let email: String
    let faxNumber: String
    let organization: String
    let address: String
    let phone: String
}
