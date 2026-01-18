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
            NavigationLink(destination: ReadingView(article: article)) {
                HStack(spacing: 12) {
                    if let coverImageUrl = article.coverImageUrl {
                        AsyncImage(url: URL(string: coverImageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "doc.text")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title)
                            .lineLimit(2)
                        HStack(spacing: 4) {
                            if let author = article.author {
                                Text(author)
                                Text("·")
                            }
                            if let host = article.url?.host {
                                Text(host)
                            }
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .lineLimit(1)
                    }

                    Spacer()

                    if article.progress > 0 {
                        CircularProgressView(progress: article.progress, size: 16)
                    }
                }
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
                article.author = result.extracted.author
                article.coverImageUrl = result.metadata.heroImage?.absoluteString
                article.content = result.extracted.extractPlainText
            } catch {
                article.title = "Failed to load"
                print("Failed to extract content: \(error)")
            }
        }

        urlString = ""
    }
}

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress >= 0.98 ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

#Preview {
    NavigationStack {
        ArticleListView()
    }
    .modelContainer(for: Article.self, inMemory: true)
}
