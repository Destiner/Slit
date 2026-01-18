//
//  ReadingView.swift
//  tldr
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftData
import SwiftUI

struct ReadingView: View {
    @Bindable var article: Article
    let wordsPerMinute: Double = 300

    @State private var currentWordIndex: Int = 0
    @State private var isPaused: Bool = false
    @State private var isFinished: Bool = false
    @State private var timer: Timer?

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

    var body: some View {
        Text(currentWord)
            .font(.system(size: 48, weight: .medium))
            .multilineTextAlignment(.center)
            .opacity(isFinished ? 0.6 : 1.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Button(action: togglePause) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                }
                .padding(.bottom, 50)
            }
        .onAppear {
            currentWordIndex = article.readingProgress
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
        let interval = pacer.interval(for: currentWordIndex)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            if !isPaused {
                advanceWord()
            }
            if currentWordIndex < words.count - 1 {
                scheduleNextWord()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFinished = true
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
