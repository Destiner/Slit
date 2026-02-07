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

    // MARK: - Extraction cleanup

    @Test func stripsFigcaptionContent() {
        let html = """
        <p>The Vision Pro represents Apple's first major new product category since the Apple Watch.</p>
        <figure>
            <img src="vision-pro.jpg" alt="Apple Vision Pro headset">
            <figcaption>The Apple Vision Pro on display at Apple Park. Photo by Nilay Patel / The Verge</figcaption>
        </figure>
        <p>It starts at $3,499 and will be available in February.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("first major new product category"))
        #expect(text.contains("starts at $3,499"))
        #expect(!text.contains("Nilay Patel"))
        #expect(!text.contains("Photo by"))
        #expect(!text.contains("on display at Apple Park"))
    }

    @Test func stripsFigcaptionCredit() {
        let html = """
        <p>The researchers gathered in the main hall.</p>
        <figure>
            <img src="hall.jpg">
            <figcaption>Getty Images</figcaption>
        </figure>
        <p>Their findings would reshape the field.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("researchers gathered"))
        #expect(text.contains("findings would reshape"))
        #expect(!text.contains("Getty Images"))
    }

    @Test func doesNotLeakImageAltText() {
        let html = """
        <p>The summit was held in Davos.</p>
        <img src="davos.jpg" alt="World Economic Forum annual meeting in Davos, Switzerland">
        <p>Leaders from 40 countries attended.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("summit was held"))
        #expect(text.contains("Leaders from 40 countries"))
        #expect(!text.contains("World Economic Forum annual meeting"))
    }

    @Test func stripsVideoElements() {
        let html = """
        <p>Watch the full keynote below.</p>
        <video controls>
            <source src="keynote.mp4" type="video/mp4">
            Your browser does not support the video tag.
        </video>
        <p>The presentation lasted two hours.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("full keynote below"))
        #expect(text.contains("presentation lasted two hours"))
        #expect(!text.contains("does not support"))
        #expect(!text.contains("video tag"))
    }

    @Test func stripsNumericFootnoteMarkers() {
        let html = """
        <p>The study found significant results [1] across all demographics [2] and confirmed earlier hypotheses [3].</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("significant results across all demographics and confirmed"))
        #expect(!text.contains("[1]"))
        #expect(!text.contains("[2]"))
        #expect(!text.contains("[3]"))
    }

    @Test func preservesNonFootnoteBrackets() {
        let html = """
        <p>The GDP growth rate [adjusted for inflation] was higher than the previous year [1] according to the report.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("[adjusted for inflation]"))
        #expect(!text.contains("[1]"))
    }

    @Test func stripsRawURLLinkText() {
        let html = """
        <p>The full report is available at <a href="https://www.example.com/reports/2024/annual-summary">https://www.example.com/reports/2024/annual-summary</a> for anyone interested.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("full report is available at"))
        #expect(text.contains("for anyone interested"))
        #expect(!text.contains("https://"))
        #expect(!text.contains("example.com"))
    }

    @Test func preservesDescriptiveLinkText() {
        let html = """
        <p>Read the <a href="https://example.com/report">full annual report</a> for more details.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("Read the full annual report for more details"))
    }

    @Test func collapsesMultipleNewlines() {
        let html = """
        <p>First section ends here.</p>
        <div></div>
        <div></div>
        <p></p>
        <p>Second section starts here.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("First section ends here."))
        #expect(text.contains("Second section starts here."))
        #expect(!text.contains("\n\n\n"))
    }

    @Test func cleansOrphanedBracketsAfterFootnoteRemoval() {
        let html = """
        <p>The treatment showed a 40% improvement [1].</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(!text.contains("  "))
        #expect(text.contains("40% improvement"))
    }

    @Test func removesDuplicateBlockquotePullQuote() {
        let html = """
        <p>In her speech, the director said that the future belongs to those who believe in the beauty of their dreams. The audience responded with a standing ovation.</p>
        <blockquote>
            <p>The future belongs to those who believe in the beauty of their dreams.</p>
        </blockquote>
        <p>The event continued with a panel discussion.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("the director said"))
        #expect(text.contains("panel discussion"))
        let range = text.range(of: "the beauty of their dreams")
        #expect(range != nil)
        if let firstRange = range {
            let remaining = text[firstRange.upperBound...]
            #expect(!remaining.contains("the beauty of their dreams"))
        }
    }

    @Test func preservesRealBlockquotes() {
        let html = """
        <p>The professor disagreed with the committee's findings.</p>
        <blockquote>
            <p>"This methodology is fundamentally flawed," Dr. Chen wrote in her response. "The sample size alone should have disqualified the study."</p>
        </blockquote>
        <p>The debate continued for months.</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("fundamentally flawed"))
        #expect(text.contains("Dr. Chen wrote"))
        #expect(text.contains("sample size alone"))
    }

    @Test func handlesRealisticArticleFragment() {
        let html = """
        <h2>The Rise of Remote Work</h2>
        <p>A recent study by Stanford researchers [1] found that remote workers were 13% more productive than their office counterparts.</p>
        <figure>
            <img src="remote-work.jpg" alt="Person working from home on laptop">
            <figcaption>Remote work has become the norm for many tech workers. Photograph: Alamy</figcaption>
        </figure>
        <p>The findings contradicted earlier research from <a href="https://www.microsoft.com/en-us/research/publication/remote-work-study">https://www.microsoft.com/en-us/research/publication/remote-work-study</a> which suggested the opposite.</p>
        <blockquote>
            <p>"We were surprised by the magnitude of the effect," said Professor Bloom.</p>
        </blockquote>
        <p>The implications for corporate real estate are significant [2].</p>
        """
        let content = extractedContent(from: html)
        let text = content.extractedText

        #expect(text.contains("The Rise of Remote Work"))
        #expect(!text.contains("Photograph: Alamy"))
        #expect(!text.contains("norm for many tech workers"))
        #expect(!text.contains("Person working from home"))
        #expect(!text.contains("[1]"))
        #expect(!text.contains("[2]"))
        #expect(!text.contains("microsoft.com"))
        #expect(text.contains("surprised by the magnitude"))
        #expect(text.contains("13% more productive"))
        #expect(text.contains("corporate real estate"))
    }
}
