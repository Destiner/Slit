//
//  Article.swift
//  tldr
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
        self.createdAt = .now
        self.readingProgress = 0
        self.lastOpenedAt = nil
        self.readAt = nil
    }

    enum ReadingStatus: Comparable {
        case inProgress
        case unread
        case read

        var sortOrder: Int {
            switch self {
            case .inProgress: return 0
            case .unread: return 1
            case .read: return 2
            }
        }
    }

    var readingStatus: ReadingStatus {
        if readAt != nil {
            return .read
        } else if readingProgress > 0 {
            return .inProgress
        } else {
            return .unread
        }
    }

    var sortDate: Date {
        switch readingStatus {
        case .inProgress:
            return lastOpenedAt ?? createdAt
        case .unread:
            return createdAt
        case .read:
            return readAt ?? createdAt
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
