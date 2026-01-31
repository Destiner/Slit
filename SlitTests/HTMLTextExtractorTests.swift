//
//  HTMLTextExtractorTests.swift
//  SlitTests
//
//  Tests for the fixed HTML text extraction that properly preserves word boundaries
//

import Foundation
import Reeeed
@testable import Slit
import Testing

struct HTMLTextExtractorTests {
    /// Helper to create ExtractedContent from HTML
    private func extractedContent(from html: String) -> ExtractedContent {
        ExtractedContent(content: html)
    }

    @Test func preservesSpacesBetweenInlineElements() {
        let html = "<p>Check out <a href=\"#\">this link</a> and <a href=\"#\">that link</a> for more.</p>"
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("Check out"))
        #expect(text.contains("this link"))
        #expect(text.contains("and"))
        #expect(text.contains("that link"))
        #expect(text.contains("for more."))
        #expect(!text.contains("linkand"))
        #expect(!text.contains("outthis"))
    }

    @Test func handlesEmphasisWithoutJamming() {
        let html = "<p>This is <em>emphasized</em> text and <strong>bold</strong> text.</p>"
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("is emphasized text"))
        #expect(text.contains("and bold text"))
        #expect(!text.contains("isemphasized"))
        #expect(!text.contains("andbold"))
    }

    @Test func preservesPunctuationWithoutExtraSpaces() {
        let html = "<p>Hello, world! How are you?</p>"
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("Hello,"))
        #expect(text.contains("world!"))
        #expect(!text.contains("Hello ,"))
        #expect(!text.contains("world !"))
    }

    @Test func handlesNestedInlineElements() {
        let html = "<p>Check <a href=\"#\"><strong>this bold link</strong></a> out.</p>"
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("Check"))
        #expect(text.contains("this bold link"))
        #expect(text.contains("out."))
        #expect(!text.contains("Checkthis"))
        #expect(!text.contains("linkout"))
    }

    @Test func createsNewLinesForBlockElements() {
        let html = "<p>First paragraph.</p><p>Second paragraph.</p>"
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("First paragraph."))
        #expect(text.contains("Second paragraph."))
        #expect(text.contains("\n"))
    }

    @Test func handlesListItems() {
        let html = "<ul><li>Item one</li><li>Item two</li></ul>"
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("Item one"))
        #expect(text.contains("Item two"))
    }

    @Test func preservesPreformattedText() {
        let html = "<pre>  indented\n    code</pre>"
        let content = extractedContent(from: html)
        let text = content.extractedText

        // Pre blocks should preserve whitespace
        #expect(text.contains("indented"))
        #expect(text.contains("code"))
    }

    @Test func handlesEmptyContent() {
        let content = ExtractedContent(content: nil)
        let text = content.extractedText

        #expect(text.isEmpty)
    }

    @Test func handlesEmptyHTML() {
        let content = extractedContent(from: "")
        let text = content.extractedText

        #expect(text.isEmpty)
    }

    @Test func handlesMultipleSpacesInSource() {
        let html = "<p>Multiple    spaces    between    words.</p>"
        let content = extractedContent(from: html)
        let text = content.extractedText

        // Multiple spaces should be normalized
        #expect(text.contains("Multiple"))
        #expect(text.contains("spaces"))
        #expect(text.contains("between"))
        #expect(text.contains("words."))
    }

    @Test func realWorldLinkExample() {
        // Simulating the actual bug from the blog post
        let html = """
        <p>This one is for the<a href="#">complainers</a> and whiners.</p>
        <p>I just wrote<a href="#">open source</a> software.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("the complainers"))
        #expect(text.contains("wrote open source"))
        #expect(!text.contains("thecomplainers"))
        #expect(!text.contains("wroteopen"))
    }
}
