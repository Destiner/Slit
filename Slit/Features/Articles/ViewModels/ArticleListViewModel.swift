//
//  ArticleListViewModel.swift
//  Slit
//
//  Created by Timur Badretdinov on 31/01/2026.
//

import SwiftUI
import SwiftData

@Observable
class ArticleListViewModel {
    var showAddAlert = false
    var urlString = ""
    var showErrorAlert = false
    var errorMessage = ""

    private let dataSource: ArticleDataSource

    init(dataSource: ArticleDataSource) {
        self.dataSource = dataSource
    }

    var isValidURL: Bool {
        URL(string: urlString)?.scheme?.hasPrefix("http") == true
    }

    func filteredAndSortedArticles(_ articles: [Article]) -> [Article] {
        articles
            .filter { $0.readingStatus != .read }
            .sorted { a, b in
                if a.readingStatus.sortOrder != b.readingStatus.sortOrder {
                    return a.readingStatus.sortOrder < b.readingStatus.sortOrder
                }
                return a.sortDate > b.sortDate
            }
    }

    func deleteArticles(_ articles: [Article], at offsets: IndexSet) {
        let sorted = filteredAndSortedArticles(articles)
        for index in offsets {
            dataSource.delete(sorted[index])
        }
    }

    func addURL(existingArticles: [Article]) {
        guard let url = URL(string: urlString) else {
            return
        }

        let normalizedInput = URLNormalizer.normalize(url)

        if let existingArticle = existingArticles.first(where: { article in
            guard let articleUrl = article.url else { return false }
            return URLNormalizer.normalize(articleUrl) == normalizedInput
        }) {
            existingArticle.readingProgress = 0
            existingArticle.readAt = nil
            existingArticle.lastOpenedAt = nil
            dataSource.save()
            urlString = ""
            return
        }

        let article = Article(url: url, title: "Loading...")
        dataSource.insert(article)

        Task {
            await ArticleImporter.importContent(for: article, context: dataSource.context)
        }

        urlString = ""
    }
}
