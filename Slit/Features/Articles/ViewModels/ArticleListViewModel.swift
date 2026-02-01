//
//  ArticleListViewModel.swift
//  Slit
//
//  Created by Timur Badretdinov on 31/01/2026.
//

import SwiftData
import SwiftUI

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
            .filter { !$0.status.isRead }
            .sorted { $0.status < $1.status }
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
            URLNormalizer.normalize(article.url) == normalizedInput
        }) {
            existingArticle.status = .unread(lastTouchedAt: .now)
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
