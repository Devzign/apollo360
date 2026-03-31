//
//  ArticleDetailView.swift
//  Apollo360
//
//  Created by Codex on 05/03/26.
//

import SwiftUI
import Combine
import UIKit

struct ArticleDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: ArticleDetailViewModel
    private let session: SessionManager

    init(articleId: Int, session: SessionManager) {
        self.session = session
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(articleId: articleId, session: session))
    }

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            let contentWidth = max(screenWidth - 24, 0)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    heroSection(contentWidth: contentWidth)

                    if viewModel.isLoading {
                        ProgressView("Loading article...")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.grey)
                    }

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundColor(AppColor.red)
                            .padding(.horizontal, 12)
                    }

                    if let article = viewModel.article {
                        summaryView(article.summary, contentWidth: contentWidth)
                        bodySectionsView(article.bodySections, contentWidth: contentWidth)
                    }
                }
                .frame(width: screenWidth, alignment: .topLeading)
                .padding(.bottom, 40)
            }
            .frame(width: screenWidth)
            .clipped()
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private func heroSection(contentWidth: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            heroImage
                .frame(width: contentWidth)
                .frame(height: 280)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.clear, Color.black.opacity(0.6)],
                                   startPoint: .center,
                                   endPoint: .bottom)
                )

            VStack(alignment: .leading, spacing: 10) {
                if let title = viewModel.article?.title {
                    Text(title)
                        .font(AppFont.display(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.82)
                }
                if let author = viewModel.article?.author {
                    HStack(spacing: 10) {
                        Group {
                            if let url = URL(string: author.image ?? "") {
                                RemoteArticleImage(url: url) {
                                    Circle().fill(Color.white.opacity(0.25))
                                }
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                            }
                        }
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("By \(author.staffName ?? "Apollo Team")")
                                .font(AppFont.body(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text(author.credentials ?? "")
                                .font(AppFont.body(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Spacer(minLength: 8)

                        Button(action: { viewModel.toggleSaved() }) {
                            Image(systemName: (viewModel.article?.isSaved ?? false) ? "heart.fill" : "heart")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor((viewModel.article?.isSaved ?? false) ? AppColor.red : AppColor.black)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.92))
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.isSaving || viewModel.article == nil)
                    }
                }
            }
            .padding(16)
        }
        .overlay(heroButtonsOverlay(contentWidth: contentWidth))
        .frame(width: contentWidth, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }

    private func heroButtonsOverlay(contentWidth: CGFloat) -> some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColor.black)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColor.black)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .frame(width: contentWidth, height: 280, alignment: .top)
    }

    private var heroImage: some View {
        Group {
            if let image = viewModel.article?.heroImage,
               let url = URL(string: resolvedImageURL(image)) {
                RemoteArticleImage(url: url) {
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

    @ViewBuilder
    private func summaryView(_ summary: [String], contentWidth: CGFloat) -> some View {
        if !summary.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundColor(AppColor.black)
                ForEach(summary, id: \.self) { point in
                    Text("• \(point)")
                        .font(AppFont.body(size: 15))
                        .foregroundColor(AppColor.grey)
                        .lineSpacing(4)
                }
            }
            .padding(14)
            .frame(width: contentWidth, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 12)
        }
    }

    @ViewBuilder
    private func bodySectionsView(_ sections: [ArticleBodySection], contentWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                if let image = section.displayImage?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !image.isEmpty,
                   !image.hasSuffix("/articles/"),
                   let url = URL(string: image) {
                    RemoteArticleImage(url: url) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.22), Color.gray.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shimmer()
                    }
                    .frame(width: contentWidth)
                    .frame(height: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                let text = section.caption?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? section.caption!
                    : (section.bodyCopy ?? "")

                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(normalizedBodyText(text, alignment: section.alignment))
                        .font(AppFont.body(size: 16))
                        .foregroundColor(AppColor.black.opacity(0.78))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: contentWidth, alignment: .leading)
                        .padding(.bottom, section.alignment?.lowercased() == "spanning" ? 8 : 0)
                }
            }
        }
        .frame(width: contentWidth, alignment: .leading)
        .padding(.horizontal, 12)
    }

    private func normalizedBodyText(_ text: String, alignment: String?) -> String {
        let htmlStripped = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let cleaned = htmlStripped
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedParagraphs = cleaned.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        // Keep paragraph breaks natural for both spanning and non-spanning content.
        if alignment?.lowercased() == "spanning" {
            return normalizedParagraphs
        }
        return normalizedParagraphs
    }

    private func resolvedImageURL(_ raw: String) -> String {
        if raw.contains("{filedir_6}") {
            return raw.replacingOccurrences(of: "{filedir_6}", with: "https://a360h.com/assets/images/articles/")
        }
        return raw
    }
}

private struct RemoteArticleImage<Placeholder: View>: View {
    @StateObject private var loader: ArticleRemoteImageLoader
    let placeholder: Placeholder

    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        _loader = StateObject(wrappedValue: ArticleRemoteImageLoader(url: url))
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

private final class ArticleRemoteImageLoader: ObservableObject {
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
