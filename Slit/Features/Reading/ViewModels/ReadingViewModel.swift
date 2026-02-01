//
//  ReadingViewModel.swift
//  Slit
//
//  Created by Timur Badretdinov on 31/01/2026.
//

import SwiftUI

@Observable
class ReadingViewModel {
    enum PlaybackState {
        case playing
        case paused
        case finished
    }

    struct HoldState {
        let startTime: Date
        let wasPlayingBefore: Bool
    }

    static let wordsPerMinute: Double = 300

    var currentWordIndex: Int = 0
    var playbackState: PlaybackState = .paused
    var holdState: HoldState?
    var wordsSinceResume: Int = 0

    private var timer: Timer?
    private var lastActivatedTime: Date?
    private let article: Article

    init(article: Article) {
        self.article = article
        currentWordIndex = article.status.readingProgress
    }

    var words: [String] {
        WordSplitter.split(article.content)
    }

    var pacer: ReadingPacer {
        ReadingPacer(words: words, baseWPM: Self.wordsPerMinute)
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

    var isPaused: Bool {
        playbackState != .playing
    }

    var isFinished: Bool {
        playbackState == .finished
    }

    func onAppear() {
        switch article.status {
        case .unread:
            article.status = .unread(lastTouchedAt: .now)
        case let .inProgress(progress, _):
            article.status = .inProgress(progress: progress, lastOpenedAt: .now)
        case .read:
            break
        }
        startTimer()
    }

    func onDisappear() {
        stopTimer()
        saveProgress()
    }

    func onPlaybackStateChange() {
        if playbackState == .paused {
            saveProgress()
        }
    }

    func onScenePhaseChange(isBackgroundOrInactive: Bool) {
        if isBackgroundOrInactive {
            // Reset gesture state to prevent spurious events when returning
            holdState = nil
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

        if holdState == nil {
            holdState = HoldState(startTime: Date(), wasPlayingBefore: playbackState == .playing)
            if playbackState == .playing {
                playbackState = .paused
            }
        }
    }

    func handlePressEnd() {
        // Ignore if we didn't have a valid press start (e.g., spurious event after background)
        guard let hold = holdState else { return }

        let pressDuration = Date().timeIntervalSince(hold.startTime)
        holdState = nil

        // Don't allow resuming if finished
        if playbackState == .finished { return }

        if pressDuration < 0.2 {
            if hold.wasPlayingBefore {
                // Was playing, now stay paused (already paused in handlePressStart)
            } else {
                wordsSinceResume = 0
                playbackState = .playing
                markInProgressIfNeeded()
            }
        } else {
            if hold.wasPlayingBefore {
                wordsSinceResume = 0
                playbackState = .playing
                markInProgressIfNeeded()
            }
        }
    }

    private func markInProgressIfNeeded() {
        if case .unread = article.status {
            article.status = .inProgress(progress: currentWordIndex, lastOpenedAt: .now)
        }
    }

    private func startTimer() {
        scheduleNextWord()
    }

    private func scheduleNextWord() {
        let interval = pacer.interval(for: currentWordIndex, rampIndex: wordsSinceResume)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            if playbackState == .playing {
                advanceWord()
                wordsSinceResume += 1
            }
            if currentWordIndex < words.count - 1 {
                scheduleNextWord()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.playbackState = .finished
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
