import Foundation
import Combine

@MainActor
final class AssessmentsViewModel: ObservableObject {
    @Published private(set) var surveys: [SurveyListItemResponse] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    @Published private(set) var detailTitle = ""
    @Published private(set) var questions: [SurveyQuestionResponse] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var isLoadingDetail = false
    @Published var detailErrorMessage: String?

    private let session: SessionManager
    private let service: FormsAPIService
    private var surveyId: Int?

    init(session: SessionManager, service: FormsAPIService = .shared) {
        self.session = session
        self.service = service
        loadSurveys()
    }

    var currentQuestion: SurveyQuestionResponse? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var isLastQuestion: Bool {
        currentIndex >= questions.count - 1
    }

    func refresh() {
        loadSurveys()
    }

    func loadSurveys() {
        guard !isLoading else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            surveys = []
            return
        }
        isLoading = true
        errorMessage = nil
        service.fetchSurveys(bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let payload):
                self.surveys = payload
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.surveys = []
            }
        }
    }

    func loadSurveyDetail(id: Int, force: Bool = false) {
        if !force, surveyId == id, !questions.isEmpty {
            if !questions.indices.contains(currentIndex) {
                currentIndex = 0
            }
            return
        }
        guard let token = session.accessToken else {
            detailErrorMessage = "You're not signed in."
            return
        }
        surveyId = id
        isLoadingDetail = true
        detailErrorMessage = nil
        service.fetchSurveyDetails(id: id, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoadingDetail = false
            switch result {
            case .success(let detail):
                self.detailTitle = detail.title
                self.questions = detail.questions
                self.currentIndex = 0
                if self.questions.isEmpty {
                    self.detailErrorMessage = "No questions available for this survey."
                }
            case .failure(let error):
                self.detailErrorMessage = error.localizedDescription
                self.questions = []
            }
        }
    }

    func selectOption(_ value: String) {
        guard let sid = surveyId,
              let token = session.accessToken,
              questions.indices.contains(currentIndex) else { return }
        questions[currentIndex].selectedValue = value
        save(question: questions[currentIndex], surveyId: sid, token: token)
    }

    func updateText(_ value: String) {
        guard questions.indices.contains(currentIndex) else { return }
        questions[currentIndex].selectedValue = value
    }

    @discardableResult
    func nextQuestion() -> Bool {
        guard questions.indices.contains(currentIndex) else { return false }
        if questions[currentIndex].questionType.lowercased().contains("textbox"),
           let sid = surveyId,
           let token = session.accessToken,
           let response = questions[currentIndex].selectedValue,
           !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            save(question: questions[currentIndex], surveyId: sid, token: token)
        }
        if isLastQuestion {
            refresh()
            return true
        } else {
            currentIndex += 1
            return false
        }
    }

    private func save(question: SurveyQuestionResponse, surveyId: Int, token: String) {
        guard let response = question.selectedValue,
              !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let request = SurveySaveRequest(questionId: question.questionId, response: response, other: question.otherText)
        service.saveSurveyResponse(surveyId: surveyId, request: request, bearerToken: token) { [weak self] result in
            guard let self else { return }
            if case .failure(let error) = result {
                self.detailErrorMessage = error.localizedDescription
            }
        }
    }
}
