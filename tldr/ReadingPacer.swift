//
//  ReadingPacer.swift
//  tldr
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import Foundation

struct ReadingPacer {
    let baseWPM: Double
    let words: [String]

    init(words: [String], baseWPM: Double = 300) {
        self.words = words
        self.baseWPM = baseWPM
    }

    /// Returns the interval in seconds for displaying the word at the given index
    func interval(for index: Int) -> Double {
        guard !words.isEmpty, index >= 0, index < words.count else {
            return baseInterval
        }

        let word = words[index]
        var multiplier = 1.0

        // Ramp up: slower at the start (first 5 words)
        multiplier *= rampUpMultiplier(for: index)

        // Slow down: slower at the end (last 5 words)
        multiplier *= rampDownMultiplier(for: index)

        // Word complexity: longer words and punctuation need more time
        multiplier *= wordComplexityMultiplier(for: word)

        return baseInterval * multiplier
    }

    // MARK: - Private

    private var baseInterval: Double {
        60.0 / baseWPM
    }

    /// Slower at the start to ease the reader in
    private func rampUpMultiplier(for index: Int) -> Double {
        let rampWords = 5
        guard index < rampWords else { return 1.0 }
        // Linear ramp from 1.5x to 1.0x over first 5 words
        let progress = Double(index) / Double(rampWords)
        return 1.5 - (0.5 * progress)
    }

    /// Slower at the end to let the reader finish comfortably
    private func rampDownMultiplier(for index: Int) -> Double {
        let rampWords = 5
        let distanceFromEnd = words.count - 1 - index
        guard distanceFromEnd < rampWords else { return 1.0 }
        // Linear ramp from 1.0x to 1.5x over last 5 words
        let progress = Double(rampWords - distanceFromEnd) / Double(rampWords)
        return 1.0 + (0.5 * progress)
    }

    /// Adjust based on word characteristics
    private func wordComplexityMultiplier(for word: String) -> Double {
        var multiplier = 1.0

        // Longer words need more time
        let length = word.count
        if length > 8 {
            multiplier += 0.3
        } else if length > 5 {
            multiplier += 0.15
        }

        // Words with sentence-ending punctuation get a pause
        if word.hasSuffix(".") || word.hasSuffix("!") || word.hasSuffix("?") {
            multiplier += 0.4
        }
        // Words with commas/semicolons get a smaller pause
        else if word.hasSuffix(",") || word.hasSuffix(";") || word.hasSuffix(":") {
            multiplier += 0.2
        }

        // Numbers can be harder to process
        if word.contains(where: { $0.isNumber }) {
            multiplier += 0.15
        }

        return multiplier
    }
}
