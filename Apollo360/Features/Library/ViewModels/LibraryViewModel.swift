//
//  LibraryViewModel.swift
//  Apollo360
//
//  Created by Codex on 05/03/26.
//

import Foundation
import Combine

struct LibraryArticle: Identifiable {
    let id: Int
    let title: String
    let imageURL: String?
    let viewingTimeText: String
    let isSaved: Bool
    let isRecentlyVisited: Bool
    let urlTitle: String?
    let videoURL: String?

    var readTimeDisplay: String {
        guard !viewingTimeText.isEmpty else { return "" }
        return "\(viewingTimeText) mins read"
    }
}

@MainActor
final class LibraryViewModel: ObservableObject {
    enum MediaType: String, CaseIterable, Identifiable {
        case all = "All Media"
        case audio = "Audio"
        case video = "Video"
        case written = "Written Articles"

        var id: String { rawValue }
    }

    private struct PagedState {
        var items: [LibraryArticle] = []
        var page: Int = 1
        var hasMore: Bool = true
        var isLoadingMore: Bool = false
    }

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedMediaType: MediaType = .all
    @Published private(set) var myList: [LibraryArticle] = []
    @Published private(set) var fitnessTarget: [LibraryArticle] = []
    @Published private(set) var nutritionTarget: [LibraryArticle] = []
    @Published private(set) var behaviorTarget: [LibraryArticle] = []

    private let session: SessionManager
    private let service: LibraryAPIService
    private let pageLimit = 20
    private var allState = PagedState()
    private var fitnessState = PagedState()
    private var nutritionState = PagedState()
    private var behaviorState = PagedState()

    init(session: SessionManager, service: LibraryAPIService = .shared) {
        self.session = session
        self.service = service
    }

    func refresh() {
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }
        isLoading = true
        errorMessage = nil

        allState = PagedState()
        fitnessState = PagedState()
        nutritionState = PagedState()
        behaviorState = PagedState()
        myList = []
        fitnessTarget = []
        nutritionTarget = []
        behaviorTarget = []

        let group = DispatchGroup()
        var capturedError: APIError?
        let sectionTypes = ["my_list", "fitness_target", "nutrition_target", "behavior_target"]

        for sectionType in sectionTypes {
            group.enter()
            loadPage(sectionType: sectionType, page: 1, token: token) { result in
                defer { group.leave() }
                if case .failure(let error) = result, capturedError == nil {
                    capturedError = error
                }
            }
        }

        group.notify(queue: .main) {
            self.isLoading = false
            if self.myList.isEmpty && self.fitnessTarget.isEmpty && self.nutritionTarget.isEmpty && self.behaviorTarget.isEmpty {
                self.errorMessage = capturedError?.localizedDescription
            }
        }
    }

    func loadMoreIfNeeded(for filter: String, currentItem item: LibraryArticle) {
        guard let token = session.accessToken else { return }
        switch filter {
        case "all":
            guard allState.hasMore, !allState.isLoadingMore, allState.items.last?.id == item.id else { return }
            allState.isLoadingMore = true
            loadPage(sectionType: "my_list", page: allState.page + 1, token: token) { _ in }
        case "fitness_target":
            guard fitnessState.hasMore, !fitnessState.isLoadingMore, fitnessState.items.last?.id == item.id else { return }
            fitnessState.isLoadingMore = true
            loadPage(sectionType: "fitness_target", page: fitnessState.page + 1, token: token) { _ in }
        case "nutrition_target":
            guard nutritionState.hasMore, !nutritionState.isLoadingMore, nutritionState.items.last?.id == item.id else { return }
            nutritionState.isLoadingMore = true
            loadPage(sectionType: "nutrition_target", page: nutritionState.page + 1, token: token) { _ in }
        case "behavior_target":
            guard behaviorState.hasMore, !behaviorState.isLoadingMore, behaviorState.items.last?.id == item.id else { return }
            behaviorState.isLoadingMore = true
            loadPage(sectionType: "behavior_target", page: behaviorState.page + 1, token: token) { _ in }
        default:
            break
        }
    }

    func filteredArticles(_ articles: [LibraryArticle]) -> [LibraryArticle] {
        switch selectedMediaType {
        case .all:
            return articles
        case .video:
            return articles.filter { !($0.videoURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
        case .written:
            return articles.filter { $0.videoURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true }
        case .audio:
            return []
        }
    }

    func articleURL(for article: LibraryArticle) -> URL? {
        guard let slug = article.urlTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !slug.isEmpty else {
            return nil
        }
        return URL(string: "https://a360h.com/articles/\(slug)")
    }

    private static func mapArticle(_ item: ArticleAPIModel) -> LibraryArticle {
        let image = firstNonEmpty(item.thumbnailURL, item.displayImage)
        let viewingTime = item.viewingTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return LibraryArticle(
            id: item.entryId,
            title: item.title.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: image,
            viewingTimeText: viewingTime,
            isSaved: item.isSaved,
            isRecentlyVisited: item.isRecentlyVisited,
            urlTitle: item.urlTitle,
            videoURL: item.videoURL
        )
    }

    private static func firstNonEmpty(_ first: String?, _ second: String?) -> String? {
        let a = first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !a.isEmpty, !a.hasSuffix("/articles/") {
            return a
        }
        let b = second?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !b.isEmpty, !b.hasSuffix("/articles/") {
            return b
        }
        return nil
    }

    private func loadPage(sectionType: String,
                          page: Int,
                          token: String,
                          completion: @escaping (Result<Void, APIError>) -> Void) {
        let requestFilter = apiFilterValue
        service.fetchArticles(
            type: sectionType,
            search: searchText,
            filter: requestFilter,
            page: page,
            limit: pageLimit,
            token: token
        ) { result in
            switch result {
            case .success(let response):
                let mapped = response.articles.map(Self.mapArticle)
                DispatchQueue.main.async {
                    self.applyPage(sectionType: sectionType, page: page, items: mapped, hasMore: response.pagination?.hasMore ?? false)
                    completion(.success(()))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.markLoadMoreDone(sectionType: sectionType)
                    completion(.failure(error))
                }
            }
        }
    }

    private func applyPage(sectionType: String, page: Int, items: [LibraryArticle], hasMore: Bool) {
        switch sectionType {
        case "my_list":
            if page == 1 { allState.items = items } else { allState.items.append(contentsOf: items) }
            allState.page = page
            allState.hasMore = hasMore
            allState.isLoadingMore = false
            myList = allState.items
        case "fitness_target":
            if page == 1 { fitnessState.items = items } else { fitnessState.items.append(contentsOf: items) }
            fitnessState.page = page
            fitnessState.hasMore = hasMore
            fitnessState.isLoadingMore = false
            fitnessTarget = fitnessState.items
        case "nutrition_target":
            if page == 1 { nutritionState.items = items } else { nutritionState.items.append(contentsOf: items) }
            nutritionState.page = page
            nutritionState.hasMore = hasMore
            nutritionState.isLoadingMore = false
            nutritionTarget = nutritionState.items
        case "behavior_target":
            if page == 1 { behaviorState.items = items } else { behaviorState.items.append(contentsOf: items) }
            behaviorState.page = page
            behaviorState.hasMore = hasMore
            behaviorState.isLoadingMore = false
            behaviorTarget = behaviorState.items
        default:
            break
        }
    }

    private func markLoadMoreDone(sectionType: String) {
        switch sectionType {
        case "my_list": allState.isLoadingMore = false
        case "fitness_target": fitnessState.isLoadingMore = false
        case "nutrition_target": nutritionState.isLoadingMore = false
        case "behavior_target": behaviorState.isLoadingMore = false
        default: break
        }
    }

    private var apiFilterValue: String {
        switch selectedMediaType {
        case .all: return "all"
        case .written: return "articles"
        case .video: return "videos"
        case .audio: return "audios"
        }
    }
}
