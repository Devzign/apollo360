//
//  RecordsResponseModels.swift
//  Apollo360
//
//  Created by Codex on 07/04/26.
//

import Foundation

struct PatientRecordsResponse: Decodable {
    let success: Bool
    let data: PatientRecordsPayload
}

struct PatientRecordsPayload: Decodable {
    let documents: PatientDocumentCollection
}

struct PatientDocumentCollection: Decodable {
    let folders: [PatientDocumentFolder]
    let officeNotes: PatientOfficeNotes
}

struct PatientDocumentFolder: Decodable, Identifiable {
    let id: Int
    let name: String
    let documentCount: Int
    let documents: [PatientDocumentItem]

    var visibleDocuments: [PatientDocumentItem] {
        documents.filter(\.isVisible)
    }
}

struct PatientDocumentItem: Decodable, Identifiable, Hashable {
    let id: Int
    let fileName: String
    let description: String
    let date: String
    let url: String
    let s3FileURL: String
    let status: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case description
        case date
        case url
        case s3FileURL = "s3_file_url"
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func decodeInt(_ key: CodingKeys) -> Int? {
            if let intValue = try? container.decode(Int.self, forKey: key) {
                return intValue
            }
            if let stringValue = try? container.decode(String.self, forKey: key) {
                return Int(stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return nil
        }

        func decodeString(_ key: CodingKeys) -> String {
            if let value = try? container.decode(String.self, forKey: key) {
                return value
            }
            if let value = try? container.decode(Int.self, forKey: key) {
                return String(value)
            }
            if let value = try? container.decode(Double.self, forKey: key) {
                return String(value)
            }
            return ""
        }

        id = decodeInt(.id) ?? 0
        fileName = decodeString(.fileName)
        description = decodeString(.description)
        date = decodeString(.date)
        url = decodeString(.url)
        s3FileURL = decodeString(.s3FileURL)
        status = decodeInt(.status)
    }

    var isVisible: Bool {
        !s3FileURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var title: String {
        let raw = fileName.split(separator: "/").last.map(String.init) ?? fileName
        return raw.removingPercentEncoding ?? raw
    }

    var detailText: String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var fileURL: URL? {
        URL(string: s3FileURL.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var fileExtension: String {
        URL(fileURLWithPath: title).pathExtension.lowercased()
    }

    var isPDF: Bool { fileExtension == "pdf" }
    var isImage: Bool { ["png", "jpg", "jpeg", "gif", "heic", "webp"].contains(fileExtension) }
}

struct PatientOfficeNotes: Decodable {
    let ioEncounters: [DoctorVisitEncounter]
    let ecwEncounters: [DoctorVisitEncounter]
}

struct DoctorVisitEncounter: Decodable, Identifiable, Hashable {
    let id: Int
    let dateUnlocked: String?
    let dateOfService: String?
    let dateOfBooking: String?
    let visitType: String?
    let cptCodes: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case dateUnlocked
        case dateOfService
        case dateOfBooking
        case visitType
        case cptCodes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = intId
        } else if let stringId = try? container.decode(String.self, forKey: .id),
                  let parsed = Int(stringId.trimmingCharacters(in: .whitespacesAndNewlines)) {
            id = parsed
        } else {
            id = 0
        }

        dateUnlocked = try? container.decode(String.self, forKey: .dateUnlocked)
        dateOfService = try? container.decode(String.self, forKey: .dateOfService)
        dateOfBooking = try? container.decode(String.self, forKey: .dateOfBooking)
        visitType = try? container.decode(String.self, forKey: .visitType)

        if let codes = try? container.decode([String].self, forKey: .cptCodes) {
            cptCodes = codes
        } else if let intCodes = try? container.decode([Int].self, forKey: .cptCodes) {
            cptCodes = intCodes.map(String.init)
        } else {
            cptCodes = []
        }
    }

    var title: String {
        let trimmed = (visitType ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Doctor Visit" : trimmed
    }

    var preferredDisplayDate: String {
        let options = [dateOfService, dateUnlocked, dateOfBooking]
        for value in options {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty, trimmed != "00.00.00" {
                return trimmed
            }
        }
        return "Date unavailable"
    }

    var visibleCPTCodes: [String] {
        cptCodes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty && $0 != "0" }
    }
}

struct DoctorVisitSummaryResponse: Decodable {
    let success: Bool
    let data: DoctorVisitSummaryPayload
}

struct DoctorVisitSummaryPayload: Decodable {
    let practitioner: VisitPractitioner
    let patient: VisitPatient
    let encounter: VisitEncounterDetail
}

struct VisitPractitioner: Decodable {
    let name: String?
    let credentials: String?
    let department: String?
    let address: VisitAddress?
    let phone: String?
    let fax: String?
    let signature: String?
}

struct VisitAddress: Decodable {
    let street: String?
    let city: String?
    let state: String?
    let zip: String?

    var formattedLines: [String] {
        let streetLine = (street ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let cityStateZip = [city, state, zip]
            .map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
            .filter { !$0.isEmpty }
        var lines: [String] = []
        if !streetLine.isEmpty { lines.append(streetLine) }
        if !cityStateZip.isEmpty {
            if cityStateZip.count >= 3 {
                lines.append("\(cityStateZip[0]), \(cityStateZip[1]) \(cityStateZip[2])")
            } else {
                lines.append(cityStateZip.joined(separator: ", "))
            }
        }
        return lines
    }
}

struct VisitPatient: Decodable {
    let name: String?
    let dob: String?
}

struct VisitEncounterDetail: Decodable {
    let facility: String?
    let date: String?
    let dateOfService: String?
    let interimHistory: String?
    let medicalHistory: VisitMedicalHistory?
    let surgicalHistory: VisitSurgicalHistory?
    let medications: VisitMedications?
    let allergies: VisitAllergies?
    let socialHistory: VisitSocialHistory?
    let familyHistory: VisitFamilyHistory?
    let conditions: [VisitDescriptionNote]
    let ros: VisitROS?
    let physicalExam: VisitPhysicalExam?
    let assessment: VisitAssessment?
    let ecgReport: String?
    let plan: [VisitPlanItem]
    let timeSpent: Int?
    let signedBy: VisitSigner?
}

struct VisitDescriptionNote: Decodable, Hashable {
    let description: String?
    let note: String?

    var formattedLine: String? {
        let value = (description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = (note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty || !noteValue.isEmpty else { return nil }
        if !value.isEmpty && !noteValue.isEmpty {
            return "\(value) (\(noteValue))"
        }
        return value.isEmpty ? noteValue : value
    }
}

struct VisitMedicalHistory: Decodable {
    let conditions: [VisitDescriptionNote]
    let note: String?
}

struct VisitSurgicalHistory: Decodable {
    let procedures: [VisitDescriptionNote]
    let note: String?
    let noSurgeries: Bool?
}

struct VisitMedicationItem: Decodable {
    let medication: String?
    let dosage: String?
    let takeVia: String?
    let takeVia2: String?
    let frequency: String?
    let notTaking: Bool?

    var formattedLine: String? {
        let pieces = [medication, dosage, takeVia, takeVia2, frequency]
            .map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
            .filter { !$0.isEmpty }
        return pieces.isEmpty ? nil : pieces.joined(separator: " | ")
    }
}

struct VisitMedications: Decodable {
    let items: [VisitMedicationItem]
    let notTaking: Bool?
}

struct VisitAllergyItem: Decodable {
    let id: Int?
    let allergy: String?
    let result: String?
    let author: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case allergy
        case result
        case author
        case updatedAt = "updated_at"
    }

    var formattedLine: String? {
        let allergyValue = (allergy ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resultValue = (result ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !allergyValue.isEmpty || !resultValue.isEmpty else { return nil }
        if !allergyValue.isEmpty && !resultValue.isEmpty {
            return "\(allergyValue): \(resultValue)"
        }
        return allergyValue.isEmpty ? resultValue : allergyValue
    }
}

struct VisitAllergies: Decodable {
    let items: [VisitAllergyItem]
    let note: String?
    let nkda: Bool?
}

struct VisitUsageItem: Decodable {
    let id: Int?
    let description: String?
    let quantity: String?
    let frequency: String?

    var formattedLine: String? {
        let base = (description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let quantityValue = (quantity ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let frequencyValue = (frequency ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty || !quantityValue.isEmpty || !frequencyValue.isEmpty else { return nil }
        var parts: [String] = []
        if !base.isEmpty { parts.append(base) }
        if !quantityValue.isEmpty { parts.append("Qty: \(quantityValue)") }
        if !frequencyValue.isEmpty { parts.append("Frequency: \(frequencyValue)") }
        return parts.joined(separator: " | ")
    }
}

struct VisitSocialUsage: Decodable {
    let status: String?
    let usages: [VisitUsageItem]
}

struct VisitSocialHistory: Decodable {
    let tobacco: VisitSocialUsage?
    let alcohol: VisitSocialUsage?
    let drugs: VisitSocialUsage?
    let maritalStatus: String?
    let children: String?
    let occupation: String?
    let notes: String?
}

struct VisitFamilyRelation: Decodable {
    let description: String?
    let brother: String?
    let sister: String?
    let mothersSide: String?
    let mother: String?
    let maternalAunt: String?
    let maternalUncle: String?
    let maternalGrandmother: String?
    let maternalGrandfather: String?
    let fathersSide: String?
    let father: String?
    let paternalAunt: String?
    let paternalUncle: String?
    let paternalGrandmother: String?
    let paternalGrandfather: String?

    var formattedLine: String? {
        let base = (description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let relatives: [(String, String?)] = [
            ("Brother", brother), ("Sister", sister), ("Mother's Side", mothersSide), ("Mother", mother),
            ("Maternal Aunt", maternalAunt), ("Maternal Uncle", maternalUncle),
            ("Maternal Grandmother", maternalGrandmother), ("Maternal Grandfather", maternalGrandfather),
            ("Father's Side", fathersSide), ("Father", father), ("Paternal Aunt", paternalAunt),
            ("Paternal Uncle", paternalUncle), ("Paternal Grandmother", paternalGrandmother),
            ("Paternal Grandfather", paternalGrandfather)
        ]
        let populated = relatives.compactMap { label, value -> String? in
            let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : "\(label): \(trimmed)"
        }
        guard !base.isEmpty || !populated.isEmpty else { return nil }
        if populated.isEmpty { return base }
        if base.isEmpty { return populated.joined(separator: ", ") }
        return "\(base) - \(populated.joined(separator: ", "))"
    }
}

struct VisitFamilyHistory: Decodable {
    let relations: [VisitFamilyRelation]
    let note: String?
}

struct VisitROSItem: Decodable {
    let description: String?
    let note: String?

    var formattedLine: String? {
        VisitDescriptionNote(description: description, note: note).formattedLine
    }
}

struct VisitROS: Decodable {
    let items: [VisitROSItem]
    let notes: String?
    let isCompleted: Bool?
}

struct VisitPhysicalExam: Decodable {
    let items: [VisitDescriptionNote]
    let notes: String?
}

struct VisitAssessmentCode: Decodable {
    let id: Int?
    let code: String?
    let staffDescription: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case staffDescription = "staff_description"
        case description
    }

    var formattedLine: String? {
        let parts = [description, staffDescription, code]
            .map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " | ")
    }
}

struct VisitAssessment: Decodable {
    let codes: [VisitAssessmentCode]
    let notes: String?
}

struct VisitPlanItem: Decodable {
    let cptCode: String?
    let description: String?
    let nonBillDesc: String?
    let notes: String?

    var formattedLine: String? {
        let parts = [cptCode, description, nonBillDesc, notes]
            .map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " | ")
    }
}

struct VisitSigner: Decodable {
    let id: Int?
    let name: String?
    let date: String?
}
