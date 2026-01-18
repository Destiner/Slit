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

    private var currentWord: String {
        guard currentWordIndex < words.count else { return "" }
        return words[currentWordIndex]
    }

    private var intervalSeconds: Double {
        60.0 / wordsPerMinute
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
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { _ in
            if !isPaused {
                advanceWord()
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
