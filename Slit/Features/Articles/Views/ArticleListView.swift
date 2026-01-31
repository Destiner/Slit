//
//  ArticleListView.swift
//  Slit
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftUI
import SwiftData

struct ArticleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var articles: [Article]
    @State private var viewModel: ArticleListViewModel?

    var body: some View {
        Group {
            if let viewModel {
                ArticleListContent(viewModel: viewModel, articles: articles)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                let dataSource = ArticleDataSource(context: modelContext)
                viewModel = ArticleListViewModel(dataSource: dataSource)
            }
        }
    }
}

private struct ArticleListContent: View {
    @Bindable var viewModel: ArticleListViewModel
    let articles: [Article]

    var body: some View {
        List {
            ForEach(viewModel.filteredAndSortedArticles(articles)) { article in
                NavigationLink(destination: ReadingView(article: article)) {
                    ArticleRowView(article: article)
                }
            }
            .onDelete { offsets in
                viewModel.deleteArticles(articles, at: offsets)
            }
        }
        .navigationTitle("Articles")
        .toolbar {
            ToolbarItem {
                Button(action: {
                    viewModel.showAddAlert = true
                }) {
                    Label("Add Article", systemImage: "plus")
                }
            }
        }
        .alert("Add Article", isPresented: $viewModel.showAddAlert) {
            TextField("https://example.com", text: $viewModel.urlString)
#if os(iOS)
                .keyboardType(.URL)
#endif
            Button("Cancel", role: .cancel) { viewModel.urlString = "" }
            Button("Add") {
                viewModel.addURL(existingArticles: articles)
            }
            .disabled(!viewModel.isValidURL)
        }
        .alert("Failed to Load Article", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct ArticleRowView: View {
    let article: Article

    var body: some View {
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

private struct CircularProgressView: View {
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
