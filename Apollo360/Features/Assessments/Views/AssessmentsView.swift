import SwiftUI

struct AssessmentsView: View {
    let horizontalPadding: CGFloat
    @StateObject private var viewModel: AssessmentsViewModel

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        _viewModel = StateObject(wrappedValue: AssessmentsViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Surveys")
                    .font(AppFont.display(size: 32, weight: .semibold))
                    .foregroundColor(AppColor.green)

                if viewModel.isLoading {
                    ProgressView("Loading surveys...")
                } else if let error = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error).foregroundColor(AppColor.red)
                        Button("Retry") { viewModel.refresh() }
                            .font(AppFont.body(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppColor.green)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                } else {
                    VStack(spacing: 14) {
                        ForEach(viewModel.surveys) { survey in
                            if survey.isCompleted {
                                SurveyCardView(survey: survey, isDisabled: true)
                            } else {
                                NavigationLink {
                                    SurveyIntroView(viewModel: viewModel, survey: survey)
                                } label: {
                                    SurveyCardView(survey: survey, isDisabled: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(AppColor.secondary.ignoresSafeArea())
    }
}

private struct SurveyCardView: View {
    let survey: SurveyListItemResponse
    let isDisabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(survey.title)
                    .font(AppFont.body(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(survey.completedQuestions)/\(survey.questionCount)")
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                if isDisabled {
                    Text("Already completed")
                        .font(AppFont.body(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                }
            }

            Spacer()
            Image(systemName: survey.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 32))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDisabled ? AppColor.green.opacity(0.52) : AppColor.green.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isDisabled ? AppColor.green.opacity(0.42) : Color.clear, lineWidth: 1)
        )
        .opacity(isDisabled ? 0.92 : 1)
    }
}

private struct SurveyIntroView: View {
    @ObservedObject var viewModel: AssessmentsViewModel
    let survey: SurveyListItemResponse

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(survey.title)
                    .font(AppFont.display(size: 36, weight: .semibold))
                    .foregroundColor(AppColor.green)
                    .multilineTextAlignment(.center)

                Text(survey.intro.htmlToPlainText)
                    .font(AppFont.body(size: 15))
                    .foregroundColor(AppColor.black.opacity(0.85))
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))

                NavigationLink {
                    SurveyQuestionScreen(viewModel: viewModel, surveyId: survey.id)
                } label: {
                    Text("Start")
                        .font(AppFont.body(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle(survey.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SurveyQuestionScreen: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: AssessmentsViewModel
    let surveyId: Int

    var body: some View {
        Group {
            if viewModel.isLoadingDetail {
                ProgressView("Loading survey...")
            } else if let error = viewModel.detailErrorMessage {
                Text(error).foregroundColor(AppColor.red)
            } else if let question = viewModel.currentQuestion {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(viewModel.detailTitle)
                            .font(AppFont.display(size: 32, weight: .semibold))
                            .foregroundColor(AppColor.green)
                            .frame(maxWidth: .infinity)

                        progressBar

                        Text(question.questionText)
                            .font(AppFont.body(size: 24, weight: .semibold))
                            .foregroundColor(AppColor.black)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        if question.questionType.lowercased().contains("textbox") {
                            TextField("Type your response...", text: Binding(
                                get: { question.selectedValue ?? "" },
                                set: { viewModel.updateText($0) }
                            ))
                            .padding(14)
                            .frame(minHeight: 120, alignment: .topLeading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColor.green.opacity(0.3), lineWidth: 1))
                        } else {
                            VStack(spacing: 12) {
                                ForEach(question.options.indices, id: \.self) { idx in
                                    let option = question.options[idx]
                                    Button {
                                        viewModel.selectOption(option)
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(AppFont.body(size: 16, weight: .medium))
                                                .foregroundColor(AppColor.black.opacity(0.8))
                                                .lineLimit(2)
                                            Spacer()
                                            Image(systemName: question.selectedValue == option ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 32))
                                                .foregroundColor(question.selectedValue == option ? AppColor.green : AppColor.grey)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 15)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(question.selectedValue == option ? AppColor.green : AppColor.grey.opacity(0.3), lineWidth: question.selectedValue == option ? 2 : 1)
                                        )
                                    }
                                    .frame(maxWidth: .infinity)
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                let finished = viewModel.nextQuestion()
                                if finished {
                                    popToAssessmentsMain()
                                }
                            } label: {
                                Text(viewModel.isLastQuestion ? "Finish" : "Next")
                                    .font(AppFont.body(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColor.green)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)

                            Button("End") { presentationMode.wrappedValue.dismiss() }
                                .font(AppFont.body(size: 18, weight: .semibold))
                                .frame(width: 110)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .foregroundColor(AppColor.black.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .clipped()
                }
            } else {
                VStack(spacing: 10) {
                    Text("No question available.")
                        .foregroundColor(AppColor.grey)
                    Button("Reload") {
                        viewModel.loadSurveyDetail(id: surveyId, force: true)
                    }
                    .font(AppFont.body(size: 14, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColor.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .background(AppColor.secondary)
        .edgesIgnoringSafeArea(.all)
        .navigationTitle("Survey")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadSurveyDetail(id: surveyId, force: true)
        }
    }

    private func popToAssessmentsMain() {
        presentationMode.wrappedValue.dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            let total = max(viewModel.questions.count, 1)
            let spacing: CGFloat = 4
            let totalSpacing = CGFloat(max(total - 1, 0)) * spacing
            let rawWidth = (geometry.size.width - totalSpacing) / CGFloat(total)
            let dotWidth = max(1, min(14, rawWidth))

            HStack(spacing: spacing) {
                ForEach(0..<total, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(idx <= viewModel.currentIndex ? AppColor.green : AppColor.grey.opacity(0.3))
                        .frame(width: dotWidth, height: 10)
                }
            }
        }
        .frame(height: 10)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

private extension String {
    var htmlToPlainText: String {
        guard let data = data(using: .utf8) else { return self }
        guard let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else {
            return self
        }
        return attributed.string
    }
}
