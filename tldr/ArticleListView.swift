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
    @Query private var articles: [Article]

    private var sortedArticles: [Article] {
        articles.sorted { a, b in
            if a.readingStatus.sortOrder != b.readingStatus.sortOrder {
                return a.readingStatus.sortOrder < b.readingStatus.sortOrder
            }
            return a.sortDate > b.sortDate
        }
    }

    @State private var showAddAlert = false
    @State private var urlString = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private var isValidURL: Bool {
        URL(string: urlString)?.scheme?.hasPrefix("http") == true
    }

    var body: some View {
        List {
            ForEach(sortedArticles) { article in
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
            .onDelete(perform: deleteArticles)
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
        .alert("Failed to Load Article", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func deleteArticles(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedArticles[index])
        }
    }

    private func addURL() {
        guard let url = URL(string: urlString) else {
            return
        }
        let article = Article(url: url, title: "Loading...")
        modelContext.insert(article)

        Task {
            // Warm up extractors on main thread before starting
            await MainActor.run {
                Reeeed.warmup(extractor: .mercury)
                Reeeed.warmup(extractor: .readability)
            }

            // Delay to let WebViews initialize (Reeeed library limitation)
            try? await Task.sleep(nanoseconds: 500_000_000)

            do {
                // Fetch HTML
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let html = String(data: data, encoding: .utf8) else {
                    throw URLError(.cannotDecodeContentData)
                }
                let baseURL = response.url ?? url

                // Try Mercury first, then Readability as fallback
                var extractedContent: ExtractedContent?
                extractedContent = try? await Reeeed.extractArticleContent(url: baseURL, html: html, extractor: .mercury)
                if extractedContent?.content == nil {
                    extractedContent = try? await Reeeed.extractArticleContent(url: baseURL, html: html, extractor: .readability)
                }

                guard let content = extractedContent, content.content != nil else {
                    throw URLError(.cannotParseResponse)
                }

                let metadata = try? await SiteMetadata.extractMetadata(fromHTML: html, baseURL: baseURL)

                article.title = content.title ?? metadata?.title ?? url.host ?? "Untitled"
                article.author = content.author
                article.coverImageUrl = metadata?.heroImage?.absoluteString
                article.content = content.extractedText
            } catch let urlError as URLError {
                modelContext.delete(article)
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    errorMessage = "No internet connection."
                case .timedOut:
                    errorMessage = "Request timed out."
                case .cannotParseResponse:
                    errorMessage = "Could not extract article content from this page."
                default:
                    errorMessage = "Network error. Please try again."
                }
                showErrorAlert = true
            } catch {
                modelContext.delete(article)
                errorMessage = "Could not load article. Please check the URL and try again."
                showErrorAlert = true
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
