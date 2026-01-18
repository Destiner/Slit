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

    init(url: URL? = nil, title: String, content: String = "") {
        self.url = url
        self.title = title
        self.content = content
        self.createdAt = .now
        self.readingProgress = 0
    }

    var wordCount: Int {
        content.split(separator: " ").count
    }

    var progress: Double {
        guard wordCount > 0 else { return 0 }
        return Double(readingProgress) / Double(wordCount)
    }
}
