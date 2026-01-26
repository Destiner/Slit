//
//  ReadingPacerTests.swift
//  SlitTests
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import Testing
@testable import Slit

struct ReadingPacerTests {
    let baseWPM: Double = 300
    var baseInterval: Double { 60.0 / baseWPM }

    // MARK: - Basic functionality

    @Test func returnsBaseIntervalForEmptyWords() {
        let pacer = ReadingPacer(words: [], baseWPM: baseWPM)
        #expect(pacer.interval(for: 0) == baseInterval)
    }

    @Test func returnsBaseIntervalForOutOfBoundsIndex() {
        let pacer = ReadingPacer(words: ["hello"], baseWPM: baseWPM)
        #expect(pacer.interval(for: -1) == baseInterval)
        #expect(pacer.interval(for: 5) == baseInterval)
    }

    // MARK: - Ramp up (start slower)

    @Test func firstWordIsSlower() {
        let words = Array(repeating: "word", count: 20)
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        let firstInterval = pacer.interval(for: 0)
        let middleInterval = pacer.interval(for: 10)
        #expect(firstInterval > middleInterval)
    }

    @Test func rampUpDecreasesOverFirstFiveWords() {
        let words = Array(repeating: "word", count: 20)
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        let intervals = (0..<5).map { pacer.interval(for: $0) }
        // Each successive word should be faster (smaller interval)
        for i in 1..<5 {
            #expect(intervals[i] < intervals[i - 1])
        }
    }

    // MARK: - Ramp down (end slower)

    @Test func lastWordIsSlower() {
        let words = Array(repeating: "word", count: 20)
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        let lastInterval = pacer.interval(for: 19)
        let middleInterval = pacer.interval(for: 10)
        #expect(lastInterval > middleInterval)
    }

    @Test func rampDownIncreasesOverLastFiveWords() {
        let words = Array(repeating: "word", count: 20)
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        let intervals = (15..<20).map { pacer.interval(for: $0) }
        // Each successive word should be slower (larger interval)
        for i in 1..<5 {
            #expect(intervals[i] > intervals[i - 1])
        }
    }

    // MARK: - Word complexity

    @Test func longerWordsAreSlower() {
        let words = ["hi", "extraordinary"]
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        // Compare at positions where ramp doesn't affect much (need longer array)
        let longWords = ["hi"] + Array(repeating: "word", count: 10) + ["extraordinary"] + Array(repeating: "word", count: 10)
        let longPacer = ReadingPacer(words: longWords, baseWPM: baseWPM)
        let shortWordInterval = longPacer.interval(for: 6)  // "word" in middle
        let longWordInterval = longPacer.interval(for: 11)   // "extraordinary"
        #expect(longWordInterval > shortWordInterval)
    }

    @Test func sentenceEndingPunctuationAddsDelay() {
        let words = Array(repeating: "word", count: 5) + ["end."] + Array(repeating: "word", count: 10)
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        let normalInterval = pacer.interval(for: 10)
        let punctuatedInterval = pacer.interval(for: 5)
        #expect(punctuatedInterval > normalInterval)
    }

    @Test func commaAddsSmallerDelay() {
        let words = Array(repeating: "word", count: 5) + ["hello,"] + Array(repeating: "word", count: 5) + ["end."] + Array(repeating: "word", count: 5)
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        let commaInterval = pacer.interval(for: 5)
        let periodInterval = pacer.interval(for: 11)
        // Both should be slower than normal, but period slower than comma
        let normalInterval = pacer.interval(for: 8)
        #expect(commaInterval > normalInterval)
        #expect(periodInterval > commaInterval)
    }

    @Test func numbersAddDelay() {
        let words = Array(repeating: "word", count: 5) + ["2026"] + Array(repeating: "word", count: 10)
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        let numberInterval = pacer.interval(for: 5)
        let normalInterval = pacer.interval(for: 10)
        #expect(numberInterval > normalInterval)
    }

    // MARK: - Short texts

    @Test func shortTextHasOverlappingRamps() {
        // With only 6 words, first 5 ramp up and last 5 ramp down overlap
        // Use identical words to isolate the ramp effect
        let words = Array(repeating: "word", count: 6)
        let pacer = ReadingPacer(words: words, baseWPM: baseWPM)
        // First word has 1.5x ramp-up + some ramp-down (distance 5 from end)
        // Last word has 1.5x ramp-down (distance 0 from end)
        // Both ends should be slower than a longer text's middle
        let firstInterval = pacer.interval(for: 0)
        let lastInterval = pacer.interval(for: 5)
        // Both should be slower than base interval
        #expect(firstInterval > baseInterval)
        #expect(lastInterval > baseInterval)
    }

    // MARK: - Custom WPM

    @Test func customWPMAffectsIntervals() {
        let words = Array(repeating: "word", count: 20)
        let slowPacer = ReadingPacer(words: words, baseWPM: 200)
        let fastPacer = ReadingPacer(words: words, baseWPM: 400)
        let slowInterval = slowPacer.interval(for: 10)
        let fastInterval = fastPacer.interval(for: 10)
        #expect(slowInterval > fastInterval)
    }
}
