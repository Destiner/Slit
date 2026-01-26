//
//  WordSplitterTests.swift
//  SlitTests
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import Testing
@testable import Slit

struct WordSplitterTests {
    @Test func splitsSimpleText() {
        let result = WordSplitter.split("hello world")
        #expect(result == ["hello", "world"])
    }

    @Test func splitsTextWithMultipleSpaces() {
        let result = WordSplitter.split("hello    world")
        #expect(result == ["hello", "world"])
    }

    @Test func splitsTextWithNewlines() {
        let result = WordSplitter.split("hello\nworld")
        #expect(result == ["hello", "world"])
    }

    @Test func splitsTextWithMixedWhitespace() {
        let result = WordSplitter.split("hello\n\n  world\t\tfoo")
        #expect(result == ["hello", "world", "foo"])
    }

    @Test func handlesLeadingAndTrailingWhitespace() {
        let result = WordSplitter.split("  hello world  ")
        #expect(result == ["hello", "world"])
    }

    @Test func handlesEmptyString() {
        let result = WordSplitter.split("")
        #expect(result == [])
    }

    @Test func handlesOnlyWhitespace() {
        let result = WordSplitter.split("   \n\t  ")
        #expect(result == [])
    }

    @Test func preservesPunctuation() {
        let result = WordSplitter.split("Hello, world!")
        #expect(result == ["Hello,", "world!"])
    }

    @Test func handlesRealWorldText() {
        let text = """
        you have three minutes
        Jan 17, 2026

        I had a dream
        """
        let result = WordSplitter.split(text)
        #expect(result == ["you", "have", "three", "minutes", "Jan", "17,", "2026", "I", "had", "a", "dream"])
    }
}
