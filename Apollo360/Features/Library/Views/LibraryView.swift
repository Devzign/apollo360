//
//  LibraryView.swift
//  Apollo360
//
//  Created by Codex on 05/03/26.
//

import SwiftUI
import Combine
import UIKit

struct LibraryView: View {
    private struct ArticleRoute: Identifiable, Hashable {
        let id: Int
    }

    @StateObject private var viewModel: LibraryViewModel
    @State private var isSortPresented = false
    @State private var selectedArticle: ArticleRoute?
    private let session: SessionManager
    let horizontalPadding: CGFloat

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.session = session
        self.horizontalPadding = horizontalPadding
        _viewModel = StateObject(wrappedValue: LibraryViewModel(session: session))
    }

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            let contentWidth = max(screenWidth - (horizontalPadding * 2), 0)
            let isInitialLoading = viewModel.isLoading
                && viewModel.myList.isEmpty
                && viewModel.fitnessTarget.isEmpty
                && viewModel.nutritionTarget.isEmpty
                && viewModel.behaviorTarget.isEmpty

            ScrollView(showsIndicators: false) {
                if isInitialLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                            .scaleEffect(1.1)
                            .accentColor(AppColor.green)
                        Text("Loading library...")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.grey)
                    }
                    .frame(width: contentWidth)
                    .frame(minHeight: proxy.size.height * 0.65, alignment: .center)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 80)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        searchBar
                        if viewModel.isLoading {
                            ProgressView("Loading articles...")
                                .font(AppFont.body(size: 14, weight: .medium))
                                .foregroundColor(AppColor.grey)
                        }

                        if let error = viewModel.errorMessage, !error.isEmpty {
                            Text(error)
                                .font(AppFont.body(size: 13, weight: .medium))
                                .foregroundColor(AppColor.red)
                        }

                        sectionTitle("My List")
                        myListSection(width: contentWidth)

                        articleSection(
                            titleForType("fitness_target"),
                            articles: viewModel.filteredArticles(viewModel.fitnessTarget),
                            filterKey: "fitness_target",
                            width: contentWidth
                        )
                        articleSection(
                            titleForType("nutrition_target"),
                            articles: viewModel.filteredArticles(viewModel.nutritionTarget),
                            filterKey: "nutrition_target",
                            width: contentWidth
                        )
                        articleSection(
                            titleForType("behavior_target"),
                            articles: viewModel.filteredArticles(viewModel.behaviorTarget),
                            filterKey: "behavior_target",
                            width: contentWidth
                        )

                        Spacer(minLength: 120)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 80)
                }
            }
            .frame(width: screenWidth)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .onAppear { viewModel.refresh() }
        .sheet(isPresented: $isSortPresented) {
            sortSheet
        }
        .background(
            NavigationLink(
                destination: selectedDestination,
                isActive: Binding(
                    get: { selectedArticle != nil },
                    set: { if !$0 { selectedArticle = nil } }
                )
            ) { EmptyView() }
            .hidden()
        )
    }

    private var selectedDestination: AnyView {
        guard let article = selectedArticle else {
            return AnyView(EmptyView())
        }

        return AnyView(ArticleDetailView(articleId: article.id, session: session))
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { viewModel.searchText = $0 }
        )
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColor.grey)
                TextField("Search", text: searchTextBinding, onCommit: {
                    viewModel.refresh()
                })
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.black.opacity(0.06), lineWidth: 1)
            )

            Button(action: {
                isSortPresented = true
            }) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColor.green)
                    .frame(width: 50, height: 50)
                    .background(AppColor.green.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.black.opacity(0.05), lineWidth: 1)
        )
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(AppFont.display(size: 18, weight: .bold))
                .foregroundColor(AppColor.black)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColor.green)
        }
    }

    @ViewBuilder
    private func myListSection(width: CGFloat) -> some View {
        let articles = viewModel.filteredArticles(viewModel.myList)
        if !articles.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(articles) { article in
                        FeaturedArticleCard(article: article, cardWidth: width) {
                            selectedArticle = ArticleRoute(id: article.id)
                        }
                        .onAppear {
                            viewModel.loadMoreIfNeeded(for: "all", currentItem: article)
                        }
                    }
                }
                .padding(.trailing, 6)
            }
            .frame(width: width, alignment: .leading)
            .clipped()
        } else {
            Text("No items in My List yet.")
                .font(AppFont.body(size: 15))
                .foregroundColor(AppColor.grey)
        }
    }

    private func articleSection(_ title: String, articles: [LibraryArticle], filterKey: String, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.display(size: 18, weight: .bold))
                .foregroundColor(AppColor.black)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(articles) { article in
                        SmallArticleCard(article: article) {
                            selectedArticle = ArticleRoute(id: article.id)
                        }
                        .onAppear {
                            viewModel.loadMoreIfNeeded(for: filterKey, currentItem: article)
                        }
                    }
                }
                .padding(.trailing, 6)
            }
            .frame(width: width, alignment: .leading)
            .clipped()
        }
    }

    private func titleForType(_ type: String) -> String {
        switch type {
        case "fitness_target":
            return "Reach Your Fitness Target"
        case "nutrition_target":
            return "Reach Your Nutrition Target"
        case "behavior_target":
            return "Reach Your Behavior Target"
        default:
            return "Articles"
        }
    }

    private var sortSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Sort by")
                .font(AppFont.display(size: 24, weight: .semibold))
                .foregroundColor(AppColor.color414141)
                .frame(maxWidth: .infinity, alignment: .center)

            Divider()

            ForEach(LibraryViewModel.MediaType.allCases) { media in
                Button {
                    viewModel.selectedMediaType = media
                    viewModel.refresh()
                    isSortPresented = false
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.selectedMediaType == media ? "checkmark" : "")
                            .foregroundColor(AppColor.green)
                            .frame(width: 18)
                        Text(media.rawValue)
                            .font(AppFont.body(size: 17, weight: viewModel.selectedMediaType == media ? .semibold : .regular))
                            .foregroundColor(viewModel.selectedMediaType == media ? AppColor.green : AppColor.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
    }
}

private struct FeaturedArticleCard: View {
    let article: LibraryArticle
    let cardWidth: CGFloat
    let onTap: () -> Void
    private let cardHeight: CGFloat = 230

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                articleImage
                    .frame(width: cardWidth, height: cardHeight)
                    .overlay(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.55)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                Text(article.title)
                    .font(AppFont.display(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColor.green.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(16)
            }
            .overlay(
                Group {
                    if article.isRecentlyVisited {
                        VStack {
                            HStack {
                                statusBadge
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(12)
                    }
                }
            )
            .frame(width: cardWidth, height: cardHeight, alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: AppColor.green.opacity(0.22), radius: 14, x: 0, y: 8)
            .clipped()
        }
        .buttonStyle(.plain)
        .frame(width: cardWidth, height: cardHeight, alignment: .leading)
    }

    private var articleImage: some View {
        Group {
            if let urlText = article.imageURL, let url = URL(string: urlText) {
                RemoteLibraryImage(url: url) {
                    fallbackImage.shimmer()
                }
            } else {
                fallbackImage.shimmer()
            }
        }
    }

    private var fallbackImage: some View {
        RoundedRectangle(cornerRadius: 0, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.22), Color.gray.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Viewed")
                .font(AppFont.body(size: 11, weight: .semibold))
        }
        .foregroundColor(AppColor.green)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColor.green.opacity(0.16))
        .clipShape(Capsule())
    }
}

private struct SmallArticleCard: View {
    let article: LibraryArticle
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    articleImage
                        .frame(width: 280, height: 190)
                        .clipped()

                    if article.isRecentlyVisited {
                        statusBadge
                            .padding(10)
                    }
                }
                if !article.readTimeDisplay.isEmpty {
                    Text(article.readTimeDisplay)
                        .font(AppFont.body(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColor.green.opacity(0.8))
                }
                Text(article.title)
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundColor(AppColor.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(12)
            }
            .frame(width: 280, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var articleImage: some View {
        Group {
            if let urlText = article.imageURL, let url = URL(string: urlText) {
                RemoteLibraryImage(url: url) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.22), Color.gray.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shimmer()
                }
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.22), Color.gray.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shimmer()
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye.fill")
                .font(.system(size: 10, weight: .semibold))
            Text("Viewed")
                .font(AppFont.body(size: 10, weight: .semibold))
        }
        .foregroundColor(AppColor.green)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(AppColor.green.opacity(0.16))
        .clipShape(Capsule())
    }
}

private struct RemoteLibraryImage<Placeholder: View>: View {
    @StateObject private var loader: LibraryRemoteImageLoader
    let placeholder: Placeholder

    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        _loader = StateObject(wrappedValue: LibraryRemoteImageLoader(url: url))
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .onAppear {
            loader.load()
        }
    }
}

private final class LibraryRemoteImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: URL
    private var hasLoaded = false

    init(url: URL) {
        self.url = url
    }

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
    }
}
