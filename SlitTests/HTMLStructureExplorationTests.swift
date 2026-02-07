//
//  HTMLStructureExplorationTests.swift
//  SlitTests
//
//  Exploration tests to analyze HTML structure from Reeeed extraction.
//  Run individually to see output: xcodebuild test -scheme Slit -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SlitTests/HTMLStructureExplorationTests
//

import Foundation
import Reeeed
@testable import Slit
import Testing

struct HTMLStructureExplorationTests {
    /// Long-form article URLs for testing
    let testURLs = [
        "https://aeon.co/essays/why-is-the-western-world-so-obsessed-with-self-improvement",
        "https://www.theverge.com/2024/1/10/24032825/apple-vision-pro-hands-on-virtual-reality",
    ]

    let tagsOfInterest = [
        "figcaption", "figure", "aside", "blockquote", "cite", "q",
        "pre", "code", "table", "footer", "nav", "a", "img", "video",
        "div", "span", "p", "h1", "h2", "h3", "section", "article",
    ]

    private func countTags(in html: String) -> [String: Int] {
        var counts: [String: Int] = [:]
        for tag in tagsOfInterest {
            let pattern = "<\(tag)[\\s>/]"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(html.startIndex..., in: html)
            let count = regex?.numberOfMatches(in: html, options: [], range: range) ?? 0
            if count > 0 {
                counts[tag] = count
            }
        }
        return counts
    }

    private func extractTagContent(tag: String, from html: String, limit: Int = 5) -> [String] {
        let pattern = "<\(tag)[^>]*>([\\s\\S]*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        return matches.prefix(limit).compactMap { match in
            guard let contentRange = Range(match.range(at: 1), in: html) else { return nil }
            let content = String(html[contentRange])
            let stripped = content.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
    }

    /// Exploration test - prints HTML structure analysis to console.
    /// Run manually and check console output.
    @Test(.disabled("Manual exploration test - enable to run"))
    func exploreReeeedHTMLStructure() async throws {
        Reeeed.warmup(extractor: .mercury)
        Reeeed.warmup(extractor: .readability)
        try await Task.sleep(nanoseconds: 500_000_000)

        for urlString in testURLs {
            guard let url = URL(string: urlString) else { continue }

            print("\n" + String(repeating: "=", count: 80))
            print("URL: \(url)")
            print(String(repeating: "=", count: 80))

            let (data, response) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { continue }
            let baseURL = response.url ?? url

            // Extract with both extractors
            let mercuryContent = try? await Reeeed.extractArticleContent(url: baseURL, html: html, extractor: .mercury)
            let readabilityContent = try? await Reeeed.extractArticleContent(url: baseURL, html: html, extractor: .readability)

            for (name, content) in [("Mercury", mercuryContent), ("Readability", readabilityContent)] {
                print("\n--- \(name) Extractor ---")
                guard let extractedHTML = content?.content else {
                    print("No content extracted")
                    continue
                }

                print("Extracted HTML size: \(extractedHTML.count) characters")

                print("\nTag counts:")
                let counts = countTags(in: extractedHTML)
                for (tag, count) in counts.sorted(by: { $0.key < $1.key }) {
                    print("  <\(tag)>: \(count)")
                }

                // Show figcaption content
                let figcaptions = extractTagContent(tag: "figcaption", from: extractedHTML)
                if !figcaptions.isEmpty {
                    print("\nFigcaption content:")
                    for (i, text) in figcaptions.enumerated() {
                        let truncated = text.count > 150 ? String(text.prefix(150)) + "..." : text
                        print("  \(i + 1). \"\(truncated)\"")
                    }
                }

                // Show aside content
                let asides = extractTagContent(tag: "aside", from: extractedHTML)
                if !asides.isEmpty {
                    print("\nAside content:")
                    for (i, text) in asides.enumerated() {
                        let truncated = text.count > 150 ? String(text.prefix(150)) + "..." : text
                        print("  \(i + 1). \"\(truncated)\"")
                    }
                }

                // Show blockquote content
                let blockquotes = extractTagContent(tag: "blockquote", from: extractedHTML)
                if !blockquotes.isEmpty {
                    print("\nBlockquote content:")
                    for (i, text) in blockquotes.enumerated() {
                        let truncated = text.count > 150 ? String(text.prefix(150)) + "..." : text
                        print("  \(i + 1). \"\(truncated)\"")
                    }
                }

                // Show extracted plain text sample
                if let extracted = content {
                    let plainText = extracted.extractedText
                    print("\nPlain text preview (first 500 chars):")
                    print("  \"\(String(plainText.prefix(500)))...\"")
                }
            }
        }
    }

    /// Quick test with sample HTML to verify tag extraction works
    @Test func sampleHTMLWithFigcaption() {
        let html = """
        <article>
            <p>Article intro paragraph.</p>
            <figure>
                <img src="photo.jpg" alt="Photo">
                <figcaption>A photo caption that should be removed. Credit: Photographer Name</figcaption>
            </figure>
            <p>More article content here.</p>
            <aside class="pullquote">This is a pull quote that duplicates text from the article.</aside>
            <blockquote>
                <p>"This is a real quote from a source," said Someone.</p>
            </blockquote>
        </article>
        """

        let content = ExtractedContent(content: html)
        let text = content.extractedText

        #expect(text.contains("Article intro paragraph"))
        #expect(text.contains("More article content"))
        #expect(!text.contains("A photo caption"))
        #expect(text.contains("pull quote"))
        #expect(text.contains("real quote from a source"))
    }
}
