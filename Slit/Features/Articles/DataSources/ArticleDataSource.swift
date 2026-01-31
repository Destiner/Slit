//
//  ArticleDataSource.swift
//  Slit
//
//  Created by Timur Badretdinov on 31/01/2026.
//

import SwiftData

struct ArticleDataSource {
    let context: ModelContext

    func fetchArticles() -> [Article] {
        let descriptor = FetchDescriptor<Article>()
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch articles: \(error)")
            return []
        }
    }

    func insert(_ article: Article) {
        context.insert(article)
        save()
    }

    func delete(_ article: Article) {
        context.delete(article)
        save()
    }

    func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save article data: \(error)")
        }
    }
}
