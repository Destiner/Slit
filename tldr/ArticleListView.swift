//
//  ArticleListView.swift
//  tldr
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftUI

struct ArticleListView: View {
    private let articles = ArticleStore.shared.articles

    var body: some View {
        List(articles) { article in
            NavigationLink(destination: ReadingView(text: article.content)) {
                Text(article.title)
                    .lineLimit(2)
            }
        }
        .navigationTitle("Articles")
    }
}

#Preview {
    NavigationStack {
        ArticleListView()
    }
}
