//
//  ReadingView.swift
//  Slit
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftData
import SwiftUI

struct ReadingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: ReadingViewModel

    init(article: Article) {
        self._viewModel = State(initialValue: ReadingViewModel(article: article))
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack {
                Spacer()
                Text(viewModel.previousWordsText)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(viewModel.isPaused && !viewModel.previousWordsText.isEmpty ? 1 : 0)
            }
            .frame(height: 160)

            Text(viewModel.currentWord)
                .font(.system(size: 48, weight: .medium))
                .multilineTextAlignment(.center)
                .opacity(viewModel.isFinished ? 0.6 : 1.0)

            Spacer()
                .frame(height: 160 + 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: viewModel.isPaused)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    viewModel.handlePressStart()
                }
                .onEnded { _ in
                    viewModel.handlePressEnd()
                }
        )
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
                .padding(.bottom, 50)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: viewModel.isPaused) { _, _ in
            viewModel.onPauseChange()
        }
        .onChange(of: scenePhase) { _, phase in
            viewModel.onScenePhaseChange(isBackgroundOrInactive: phase == .background || phase == .inactive)
        }
    }
}

#Preview {
    let article = Article(title: "Sample", content: "This is a sample text for testing the speed reading view.")
    return NavigationStack {
        ReadingView(article: article)
    }
    .modelContainer(for: Article.self, inMemory: true)
}
