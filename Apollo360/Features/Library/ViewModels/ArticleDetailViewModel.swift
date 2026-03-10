//
//  ArticleDetailViewModel.swift
//  Apollo360
//
//  Created by Codex on 05/03/26.
//

import Foundation
import Combine

@MainActor
final class ArticleDetailViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published private(set) var article: ArticleDetailResponse?

    private let articleId: Int
    private let session: SessionManager
    private let service: LibraryAPIService

    init(articleId: Int, session: SessionManager, service: LibraryAPIService = .shared) {
        self.articleId = articleId
        self.session = session
        self.service = service
    }

    func load() {
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }
        isLoading = true
        errorMessage = nil
        service.fetchArticleDetails(id: articleId, token: token) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let payload):
                    self.article = payload
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func toggleSaved() {
        guard !isSaving,
              let token = session.accessToken,
              let current = article else { return }

        let newValue = !current.isSaved
        isSaving = true
        errorMessage = nil
        article = ArticleDetailResponse(
            entryId: current.entryId,
            title: current.title,
            urlTitle: current.urlTitle,
            heroImage: current.heroImage,
            viewingTime: current.viewingTime,
            author: current.author,
            summary: current.summary,
            bodySections: current.bodySections,
            isSaved: newValue,
            relatedArticles: current.relatedArticles
        )

        service.setArticleSaved(id: articleId, value: newValue, token: token) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isSaving = false
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    if let current = self.article {
                        self.article = ArticleDetailResponse(
                            entryId: current.entryId,
                            title: current.title,
                            urlTitle: current.urlTitle,
                            heroImage: current.heroImage,
                            viewingTime: current.viewingTime,
                            author: current.author,
                            summary: current.summary,
                            bodySections: current.bodySections,
                            isSaved: !newValue,
                            relatedArticles: current.relatedArticles
                        )
                    }
                }
            }
        }
    }
}
