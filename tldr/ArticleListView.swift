//
//  ArticleListView.swift
//  tldr
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftUI
import SwiftData
import Reeeed

struct ArticleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Article.createdAt, order: .reverse) private var articles: [Article]

    @State private var showAddAlert = false
    @State private var urlString = ""

    private var isValidURL: Bool {
        URL(string: urlString)?.scheme?.hasPrefix("http") == true
    }

    var body: some View {
        List(articles) { article in
            NavigationLink(destination: ReadingView(text: article.content)) {
                Text(article.title)
                    .lineLimit(2)
            }
        }
        .navigationTitle("Articles")
        .toolbar {
            ToolbarItem {
                Button(action: {
                    showAddAlert = true
                }) {
                    Label("Add Article", systemImage: "plus")
                }
            }
        }
        .alert("Add Article", isPresented: $showAddAlert) {
            TextField("https://example.com", text: $urlString)
#if os(iOS)
                .keyboardType(.URL)
#endif
            Button("Cancel", role: .cancel) { urlString = "" }
            Button("Add", action: addURL)
                .disabled(!isValidURL)
        }
    }

    private func addURL() {
        guard let url = URL(string: urlString) else {
            return
        }
        let article = Article(url: url, title: "Loading...")
        modelContext.insert(article)

        Task {
            do {
                let result = try await Reeeed.fetchAndExtractContent(fromURL: url)
                article.title = result.title ?? url.host ?? "Untitled"
                article.content = result.extracted.extractPlainText ?? ""
            } catch {
                article.title = "Failed to load"
                print("Failed to extract content: \(error)")
            }
        }

        urlString = ""
    }
}

#Preview {
    NavigationStack {
        ArticleListView()
    }
    .modelContainer(for: Article.self, inMemory: true)
}
