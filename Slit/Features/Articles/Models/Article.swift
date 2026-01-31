//
//  Article.swift
//  Slit
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import Foundation
import SwiftData

@Model
final class Article {
    var url: URL?
    var title: String
    var author: String?
    var coverImageUrl: String?
    var content: String
    var createdAt: Date
    var readingProgress: Int
    var lastOpenedAt: Date?
    var readAt: Date?

    init(url: URL? = nil, title: String, content: String = "") {
        self.url = url
        self.title = title
        self.content = content
        createdAt = .now
        readingProgress = 0
        lastOpenedAt = nil
        readAt = nil
    }

    enum ReadingStatus: Comparable {
        case inProgress
        case unread
        case read

        var sortOrder: Int {
            switch self {
            case .inProgress: 0
            case .unread: 1
            case .read: 2
            }
        }
    }

    var readingStatus: ReadingStatus {
        if readAt != nil {
            .read
        } else if readingProgress > 0 {
            .inProgress
        } else {
            .unread
        }
    }

    var sortDate: Date {
        switch readingStatus {
        case .inProgress:
            lastOpenedAt ?? createdAt
        case .unread:
            createdAt
        case .read:
            readAt ?? createdAt
        }
    }

    var wordCount: Int {
        content.split(separator: " ").count
    }

    var progress: Double {
        guard wordCount > 0 else { return 0 }
        return Double(readingProgress) / Double(wordCount)
    }
}
