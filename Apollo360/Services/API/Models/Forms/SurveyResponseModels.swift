import Foundation

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
