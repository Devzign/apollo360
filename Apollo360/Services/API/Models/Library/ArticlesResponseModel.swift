//
//  ArticlesResponseModel.swift
//  Apollo360
//
//  Created by Codex on 05/03/26.
//

import Foundation

struct ArticlesAPIResponse: Decodable {
    let type: String?
    let articles: [ArticleAPIModel]
    let pagination: ArticlesPagination?
}

struct ArticlesPagination: Decodable {
    let total: Int?
    let page: Int?
    let limit: Int?
    let hasMore: Bool?
}

struct ArticleAPIModel: Decodable {
    let entryId: Int
    let title: String
    let urlTitle: String?
    let viewingTime: String?
    let displayImage: String?
    let thumbnailURL: String?
    let videoURL: String?
    let isSaved: Bool
    let isRecentlyVisited: Bool

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case title
        case urlTitle = "url_title"
        case viewingTime = "viewing_time"
        case displayImage = "display_image"
        case thumbnailURL = "thumbnail_url"
        case videoURL = "video_url"
        case isSaved = "is_saved"
        case isRecentlyVisited = "is_recently_visited"
    }
}

struct ArticleDetailResponse: Decodable {
    let entryId: Int
    let title: String
    let urlTitle: String?
    let heroImage: String?
    let viewingTime: String?
    let author: ArticleAuthor?
    let summary: [String]
    let bodySections: [ArticleBodySection]
    let isSaved: Bool
    let relatedArticles: [ArticleAPIModel]

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case title
        case urlTitle = "url_title"
        case heroImage = "hero_image"
        case viewingTime = "viewing_time"
        case author
        case summary
        case bodySections = "body_sections"
        case isSaved = "is_saved"
        case relatedArticles = "related_articles"
    }
}

struct ArticleAuthor: Decodable {
    let staffName: String?
    let credentials: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case staffName = "staff_name"
        case credentials
        case image
    }
}

struct ArticleBodySection: Decodable {
    let subheader: String?
    let bodyCopy: String?
    let displayImage: String?
    let caption: String?
    let alignment: String?

    enum CodingKeys: String, CodingKey {
        case subheader
        case bodyCopy = "body_copy"
        case displayImage = "display_image"
        case caption
        case alignment
    }
}
