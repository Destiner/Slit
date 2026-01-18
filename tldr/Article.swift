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
    var content: String
    var createdAt: Date

    init(url: URL? = nil, title: String, content: String = "") {
        self.url = url
        self.title = title
        self.content = content
        self.createdAt = .now
    }
}
