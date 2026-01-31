//
//  ReadingViewModel.swift
//  Slit
//
//  Created by Timur Badretdinov on 31/01/2026.
//

import SwiftUI

@Observable
class ReadingViewModel {
    var currentWordIndex: Int = 0
    var isPaused: Bool = true
    var isFinished: Bool = false
    var isHolding: Bool = false
    var wasPlayingBeforeHold: Bool = false
    var pressStartTime: Date?
    var wordsSinceResume: Int = 0

    private var timer: Timer?
    private var lastActivatedTime: Date?
    private let article: Article
    private let wordsPerMinute: Double = 300

    init(article: Article) {
        self.article = article
        currentWordIndex = article.status.readingProgress
    }

    var words: [String] {
        WordSplitter.split(article.content)
    }

    var pacer: ReadingPacer {
        ReadingPacer(words: words, baseWPM: wordsPerMinute)
    }

    var currentWord: String {
        guard currentWordIndex < words.count else { return "" }
        return words[currentWordIndex]
    }

    var previousWordsText: String {
        let startIndex = max(0, currentWordIndex - 25)
        let endIndex = currentWordIndex
        guard startIndex < endIndex else { return "" }
        return words[startIndex ..< endIndex].joined(separator: " ")
    }

    var progress: Double {
        guard words.count > 1 else { return 0 }
        return Double(currentWordIndex) / Double(words.count - 1)
    }

    func onAppear() {
        article.status = .inProgress(progress: currentWordIndex, lastOpenedAt: .now)
        startTimer()
    }

    func onDisappear() {
        stopTimer()
        saveProgress()
    }

    func onPauseChange() {
        if isPaused {
            saveProgress()
        }
    }

    func onScenePhaseChange(isBackgroundOrInactive: Bool) {
        if isBackgroundOrInactive {
            // Reset gesture state to prevent spurious events when returning
            isHolding = false
            pressStartTime = nil
            saveProgress()
        } else {
            // Mark when we became active to ignore spurious gesture events
            lastActivatedTime = Date()
        }
    }

    func handlePressStart() {
        // Ignore spurious gesture events that fire immediately after returning from background
        // These events fire within ~50ms; real user taps take longer
        if let lastActivated = lastActivatedTime,
           Date().timeIntervalSince(lastActivated) < 0.1
        {
            return
        }

        if !isHolding {
            isHolding = true
            pressStartTime = Date()
            wasPlayingBeforeHold = !isPaused
            if !isPaused {
                isPaused = true
            }
        }
    }

    func handlePressEnd() {
        // Ignore if we didn't have a valid press start (e.g., spurious event after background)
        guard isHolding else { return }

        let pressDuration = Date().timeIntervalSince(pressStartTime ?? Date())
        isHolding = false
        pressStartTime = nil

        if pressDuration < 0.2 {
            if wasPlayingBeforeHold {
                // Was playing, now stay paused (already paused in handlePressStart)
            } else {
                wordsSinceResume = 0
                isPaused = false
            }
        } else {
            if wasPlayingBeforeHold {
                wordsSinceResume = 0
                isPaused = false
            }
        }
    }

    private func startTimer() {
        scheduleNextWord()
    }

    private func scheduleNextWord() {
        let interval = pacer.interval(for: currentWordIndex, rampIndex: wordsSinceResume)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            if !isPaused {
                advanceWord()
                wordsSinceResume += 1
            }
            if currentWordIndex < words.count - 1 {
                scheduleNextWord()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isFinished = true
                    self.isPaused = true
                    self.article.status = .read(readAt: .now)
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func advanceWord() {
        if currentWordIndex < words.count - 1 {
            currentWordIndex += 1
        }
    }

    private func saveProgress() {
        if case let .inProgress(_, lastOpenedAt) = article.status {
            article.status = .inProgress(progress: currentWordIndex, lastOpenedAt: lastOpenedAt)
        }
    }
}
