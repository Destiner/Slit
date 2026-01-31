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
    /// Extracts plain text from HTML content, properly preserving word boundaries.
    var extractedText: String {
        guard let content,
              let data = content.data(using: .utf8),
              let parsed = try? HTMLDocument(data: data)
        else {
            return ""
        }

        var paragraphs = [""]
        let blockLevelTags = Set<String>(["p", "section", "li", "div", "h1", "h2", "h3", "h4", "h5", "h6", "pre", "blockquote", "article", "header", "footer", "nav", "aside", "main", "figure", "figcaption", "table", "tr", "td", "th"])
        var withinPre = 0

        parsed.body?.traverseChildrenForExtraction(
            onEnterElement: { el in
                guard let tag = el.tag?.lowercased() else { return }

                if tag == "pre" {
                    withinPre += 1
                }

                if blockLevelTags.contains(tag) {
                    paragraphs.append("")
                }
            },
            onExitElement: { el in
                if el.tag?.lowercased() == "pre" {
                    withinPre -= 1
                }
            },
            onText: { str in
                if withinPre > 0 {
                    paragraphs[paragraphs.count - 1] += str
                } else {
                    // Normalize whitespace: collapse multiple spaces/newlines to single space
                    let normalized = str.replacingOccurrences(
                        of: "\\s+",
                        with: " ",
                        options: .regularExpression
                    )

                    if !normalized.trimmingCharacters(in: .whitespaces).isEmpty {
                        let current = paragraphs[paragraphs.count - 1]

                        // If current paragraph doesn't end with space and normalized doesn't start with space,
                        // and both have content, we need to check if a space is needed
                        if !current.isEmpty,
                           !current.hasSuffix(" "),
                           !normalized.hasPrefix(" ")
                        {
                            // Check if normalized starts with punctuation
                            let firstChar = normalized.trimmingCharacters(in: .whitespaces).first
                            let isPunctuation = firstChar.map {
                                CharacterSet.punctuationCharacters.contains($0.unicodeScalars.first!)
                            } ?? false

                            if !isPunctuation {
                                paragraphs[paragraphs.count - 1] += " "
                            }
                        }

                        paragraphs[paragraphs.count - 1] += normalized
                    }
                }
            }
        )

        return paragraphs
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

extension Fuzi.XMLElement {
    func traverseChildrenForExtraction(
        onEnterElement: (Fuzi.XMLElement) -> Void,
        onExitElement: (Fuzi.XMLElement) -> Void,
        onText: (String) -> Void
    ) {
        for node in childNodes(ofTypes: [.Element, .Text]) {
            switch node.type {
            case .Text:
                onText(node.stringValue)
            case .Element:
                if let el = node as? Fuzi.XMLElement {
                    onEnterElement(el)
                    el.traverseChildrenForExtraction(
                        onEnterElement: onEnterElement,
                        onExitElement: onExitElement,
                        onText: onText
                    )
                    onExitElement(el)
                }
            default: ()
            }
        }
    }
}
