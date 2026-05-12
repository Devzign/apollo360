import Foundation
import Combine

struct SurveyListItemResponse: Decodable, Identifiable {
    let id: Int
    let title: String
    let intro: String
    let questionCount: Int
    let completedQuestions: Int
    let isCompleted: Bool
    let lastUpdated: String?
}

struct SurveyDetailResponse: Decodable {
    let id: Int
    let title: String
    let intro: String
    let questions: [SurveyQuestionResponse]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case intro
        case questions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        intro = try container.decodeIfPresent(String.self, forKey: .intro) ?? ""
        questions = try container.decodeIfPresent([SurveyQuestionResponse].self, forKey: .questions) ?? []
    }
}

struct SurveyQuestionResponse: Decodable, Identifiable {
    let questionId: Int
    let questionText: String
    let sectionHeader: String?
    let sectionIntro: String?
    let questionType: String
    let options: [String]
    var selectedValue: String?
    var otherText: String?

    var id: Int { questionId }

    private enum CodingKeys: String, CodingKey {
        case questionId
        case questionText
        case sectionHeader
        case sectionIntro
        case questionType
        case options
        case selectedValue
        case otherText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try container.decodeIfPresent(Int.self, forKey: .questionId) ?? 0
        questionText = try container.decodeIfPresent(String.self, forKey: .questionText) ?? ""
        sectionHeader = try container.decodeIfPresent(String.self, forKey: .sectionHeader)
        sectionIntro = try container.decodeIfPresent(String.self, forKey: .sectionIntro)
        questionType = try container.decodeIfPresent(String.self, forKey: .questionType) ?? ""
        options = try container.decodeIfPresent([String].self, forKey: .options) ?? []
        otherText = try container.decodeIfPresent(String.self, forKey: .otherText)

        if let value = try? container.decodeIfPresent(String.self, forKey: .selectedValue) {
            selectedValue = value
        } else if let values = try? container.decodeIfPresent([String?].self, forKey: .selectedValue) {
            selectedValue = values.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty })
        } else if let values = try? container.decodeIfPresent([String].self, forKey: .selectedValue) {
            selectedValue = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty })
        } else {
            selectedValue = nil
        }
    }
}

struct SurveySaveRequest: Encodable {
    let questionId: Int
    let response: String
    let other: String?
}

struct SurveySaveResponse: Decodable {
    let success: Bool
    let message: String?
}
