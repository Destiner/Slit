//
//  HTMLTextExtractor.swift
//  Slit
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import Foundation
import Fuzi
import Reeeed

extension ExtractedContent {
    private static let skipTags: Set<String> = [
        "figcaption", "img", "video", "source", "picture",
    ]

    private static let blockLevelTags: Set<String> = [
        "p", "section", "li", "div", "h1", "h2", "h3", "h4", "h5", "h6",
        "pre", "blockquote", "article", "header", "footer", "nav", "aside",
        "main", "figure", "table", "tr", "td", "th",
    ]

    /// Extracts plain text from HTML content, properly preserving word boundaries.
    var extractedText: String {
        guard let content,
              let data = content.data(using: .utf8),
              let parsed = try? HTMLDocument(data: data)
        else {
            return ""
        }

        var paragraphs: [(text: String, isBlockquote: Bool)] = [("", false)]
        var withinPre = 0
        var withinBlockquote = 0

        parsed.body?.traverseChildrenForExtraction(
            onEnterElement: { el in
                guard let tag = el.tag?.lowercased() else { return true }

                if Self.skipTags.contains(tag) {
                    return false
                }

                if tag == "pre" {
                    withinPre += 1
                }

                if tag == "blockquote" {
                    withinBlockquote += 1
                }

                if Self.blockLevelTags.contains(tag) {
                    paragraphs.append(("", withinBlockquote > 0))
                }

                return true
            },
            onExitElement: { el in
                guard let tag = el.tag?.lowercased() else { return }
                if tag == "pre" {
                    withinPre -= 1
                }
                if tag == "blockquote" {
                    withinBlockquote -= 1
                }
            },
            onText: { str in
                if withinPre > 0 {
                    paragraphs[paragraphs.count - 1].text += str
                } else {
                    let normalized = str.replacingOccurrences(
                        of: "\\s+",
                        with: " ",
                        options: .regularExpression
                    )

                    if !normalized.trimmingCharacters(in: .whitespaces).isEmpty {
                        let current = paragraphs[paragraphs.count - 1].text

                        if !current.isEmpty,
                           !current.hasSuffix(" "),
                           !normalized.hasPrefix(" ")
                        {
                            let firstChar = normalized.trimmingCharacters(in: .whitespaces).first
                            let isPunctuation = firstChar.map {
                                CharacterSet.punctuationCharacters.contains($0.unicodeScalars.first!)
                            } ?? false

                            if !isPunctuation {
                                paragraphs[paragraphs.count - 1].text += " "
                            }
                        }

                        paragraphs[paragraphs.count - 1].text += normalized
                    }
                }
            }
        )

        // Trim, clean, and filter paragraphs
        var cleaned = paragraphs
            .map { (text: $0.text.trimmingCharacters(in: .whitespaces), isBlockquote: $0.isBlockquote) }
            .filter { !$0.text.isEmpty }
            .map { para -> (text: String, isBlockquote: Bool) in
                var text = para.text
                text = text.replacingOccurrences(of: "\\s?\\[\\d+\\]", with: "", options: .regularExpression)
                text = text.replacingOccurrences(of: "https?://\\S+", with: "", options: .regularExpression)
                text = text.replacingOccurrences(of: "\\(\\s*\\)", with: "", options: .regularExpression)
                text = text.replacingOccurrences(of: "\\[\\s*\\]", with: "", options: .regularExpression)
                text = text.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
                text = text.trimmingCharacters(in: .whitespaces)
                return (text: text, isBlockquote: para.isBlockquote)
            }
            .filter { !$0.text.isEmpty }

        // Pull quote dedup: remove blockquote text that appears verbatim in non-blockquote text
        let nonBlockquoteText = cleaned
            .filter { !$0.isBlockquote }
            .map(\.text)
            .joined(separator: " ")
            .lowercased()
        cleaned = cleaned.filter { para in
            guard para.isBlockquote else { return true }
            let normalizedQuote = para.text
                .trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
                .lowercased()
            guard normalizedQuote.count >= 20 else { return true }
            return !nonBlockquoteText.contains(normalizedQuote)
        }

        var result = cleaned.map(\.text).joined(separator: "\n")
        result = result.replacingOccurrences(of: "\\n{2,}", with: "\n", options: .regularExpression)

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Fuzi.XMLElement {
    func traverseChildrenForExtraction(
        onEnterElement: (Fuzi.XMLElement) -> Bool,
        onExitElement: (Fuzi.XMLElement) -> Void,
        onText: (String) -> Void
    ) {
        for node in childNodes(ofTypes: [.Element, .Text]) {
            switch node.type {
            case .Text:
                onText(node.stringValue)
            case .Element:
                if let el = node as? Fuzi.XMLElement {
                    let shouldTraverse = onEnterElement(el)
                    if shouldTraverse {
                        el.traverseChildrenForExtraction(
                            onEnterElement: onEnterElement,
                            onExitElement: onExitElement,
                            onText: onText
                        )
                        onExitElement(el)
                    }
                }
            default: ()
            }
        }
    }
}
