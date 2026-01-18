//
//  ReadingView.swift
//  tldr
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftUI

struct ReadingView: View {
    let text: String
    let wordsPerMinute: Double = 300

    @State private var currentWordIndex: Int = 0
    @State private var isPaused: Bool = false
    @State private var timer: Timer?

    private var words: [String] {
        WordSplitter.split(text)
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
            startTimer()
        }
        .onDisappear {
            stopTimer()
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
    }
}

#Preview {
    NavigationStack {
        ReadingView(text: "This is a sample text for testing the speed reading view.")
    }
}
