//
//  ArticleStore.swift
//  tldr
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import Foundation
import SwiftData

enum ArticleStore {
    static func seedInitialArticles(context: ModelContext) {
        let descriptor = FetchDescriptor<Article>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let articles: [Article] = []

        for article in articles {
            context.insert(article)
        }
    }
}
