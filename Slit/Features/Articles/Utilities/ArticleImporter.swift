//
//  ArticleImporter.swift
//  Slit
//
//  Created by Timur Badretdinov on 29/01/2026.
//

import Foundation
import Reeeed
import SwiftData

enum ArticleImporter {
    enum ImportError: Error {
        case noURL
        case networkError(String)
        case parseError
    }

    @MainActor
    static func importContent(for article: Article, context: ModelContext) async {
        let url = article.url

        // Warm up extractors on main thread before starting
        Reeeed.warmup(extractor: .mercury)
        Reeeed.warmup(extractor: .readability)

        // Delay to let WebViews initialize (Reeeed library limitation)
        try? await Task.sleep(nanoseconds: 500_000_000)

        do {
            // Fetch HTML
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            let baseURL = response.url ?? url

            // Extract with both Mercury and Readability, use whichever gets more content
            let mercuryContent = try? await Reeeed.extractArticleContent(url: baseURL, html: html, extractor: .mercury)
            let readabilityContent = try? await Reeeed.extractArticleContent(url: baseURL, html: html, extractor: .readability)

            let mercuryLength = mercuryContent?.content?.count ?? 0
            let readabilityLength = readabilityContent?.content?.count ?? 0

            let content: ExtractedContent
            if mercuryLength >= readabilityLength, mercuryLength > 0 {
                content = mercuryContent!
            } else if readabilityLength > 0 {
                content = readabilityContent!
            } else {
                throw URLError(.cannotParseResponse)
            }

            let metadata = try? await SiteMetadata.extractMetadata(fromHTML: html, baseURL: baseURL)

            article.title = content.title ?? metadata?.title ?? url.host ?? "Untitled"
            article.author = content.author
            article.coverImageUrl = metadata?.heroImage?.absoluteString
            article.html = content.content ?? ""
            article.content = content.extractedText
        } catch {
            context.delete(article)
        }
    }
}
