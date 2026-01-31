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
    enum ReadingStatus: Codable, Comparable {
        case unread(createdAt: Date)
        case inProgress(progress: Int, lastOpenedAt: Date)
        case read(readAt: Date)

        var isRead: Bool {
            if case .read = self { return true }
            return false
        }

        var readingProgress: Int {
            if case let .inProgress(progress, _) = self {
                return progress
            }
            return 0
        }

        // MARK: - Comparable

        /// Sort order: inProgress first, then unread, then read.
        /// Within the same status, newer dates come first.
        static func < (lhs: ReadingStatus, rhs: ReadingStatus) -> Bool {
            if lhs.sortPriority != rhs.sortPriority {
                return lhs.sortPriority < rhs.sortPriority
            }
            return lhs.date > rhs.date
        }

        private var sortPriority: Int {
            switch self {
            case .inProgress: 0
            case .unread: 1
            case .read: 2
            }
        }

        private var date: Date {
            switch self {
            case let .inProgress(_, lastOpenedAt): lastOpenedAt
            case let .unread(createdAt): createdAt
            case let .read(readAt): readAt
            }
        }
    }

    var url: URL
    var title: String
    var author: String?
    var coverImageUrl: String?
    var html: String
    var content: String
    var status: ReadingStatus

    init(url: URL, title: String, html: String = "", content: String = "") {
        self.url = url
        self.title = title
        self.html = html
        self.content = content
        status = .unread(createdAt: .now)
    }

    var wordCount: Int {
        content.split(separator: " ").count
    }

    var progress: Double {
        guard wordCount > 0 else { return 0 }
        return Double(status.readingProgress) / Double(wordCount)
    }
}
