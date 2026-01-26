//
//  ReadingView.swift
//  Slit
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftData
import SwiftUI

struct ReadingView: View {
    @Bindable var article: Article
    let wordsPerMinute: Double = 300

    @State private var currentWordIndex: Int = 0
    @State private var isPaused: Bool = true
    @State private var isFinished: Bool = false
    @State private var timer: Timer?
    @State private var isHolding: Bool = false
    @State private var wasPlayingBeforeHold: Bool = false
    @State private var pressStartTime: Date?
    @State private var wordsSinceResume: Int = 0

    private var words: [String] {
        WordSplitter.split(article.content)
    }

    private var pacer: ReadingPacer {
        ReadingPacer(words: words, baseWPM: wordsPerMinute)
    }

    private var currentWord: String {
        guard currentWordIndex < words.count else { return "" }
        return words[currentWordIndex]
    }

    private var previousWordsText: String {
        let startIndex = max(0, currentWordIndex - 40)
        let endIndex = currentWordIndex
        guard startIndex < endIndex else { return "" }
        return words[startIndex..<endIndex].joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack {
                Spacer()
                Text(previousWordsText)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(isPaused && !previousWordsText.isEmpty ? 1 : 0)
            }
            .frame(height: 160)

            Text(currentWord)
                .font(.system(size: 48, weight: .medium))
                .multilineTextAlignment(.center)
                .opacity(isFinished ? 0.6 : 1.0)

            Spacer()
                .frame(height: 160 + 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isPaused)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding {
                            isHolding = true
                            pressStartTime = Date()
                            wasPlayingBeforeHold = !isPaused
                            if !isPaused {
                                isPaused = true
                            }
                        }
                    }
                    .onEnded { _ in
                        let pressDuration = Date().timeIntervalSince(pressStartTime ?? Date())
                        isHolding = false
                        pressStartTime = nil

                        if pressDuration < 0.2 {
                            // Short tap - toggle pause permanently
                            if wasPlayingBeforeHold {
                                // Was playing, now stay paused (we already paused in onChanged)
                            } else {
                                // Was paused, resume
                                wordsSinceResume = 0
                                isPaused = false
                            }
                        } else {
                            // Long press - restore previous state
                            if wasPlayingBeforeHold {
                                wordsSinceResume = 0
                                isPaused = false
                            }
                        }
                    }
            )
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 50)
            }
        .onAppear {
            currentWordIndex = article.readingProgress
            article.lastOpenedAt = .now
            startTimer()
        }
        .onDisappear {
            stopTimer()
            saveProgress()
        }
    }

    private func startTimer() {
        scheduleNextWord()
    }

    private func scheduleNextWord() {
        let interval = pacer.interval(for: currentWordIndex, rampIndex: wordsSinceResume)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            if !isPaused {
                advanceWord()
                wordsSinceResume += 1
            }
            if currentWordIndex < words.count - 1 {
                scheduleNextWord()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFinished = true
                    isPaused = true
                    article.readAt = .now
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

    private func togglePause() {
        isPaused.toggle()
        if isPaused {
            saveProgress()
        }
    }

    private func saveProgress() {
        article.readingProgress = currentWordIndex
    }
}

#Preview {
    let article = Article(title: "Sample", content: "This is a sample text for testing the speed reading view.")
    return NavigationStack {
        ReadingView(article: article)
    }
    .modelContainer(for: Article.self, inMemory: true)
}
