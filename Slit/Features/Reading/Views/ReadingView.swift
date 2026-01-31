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
        _viewModel = State(initialValue: ReadingViewModel(article: article))
    }

    var body: some View {
        GeometryReader { geometry in
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
            .overlay(alignment: .bottom) {
                Text("tap anywhere to start")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .opacity(viewModel.isPaused && !viewModel.isFinished ? 1 : 0)
                    .padding(.bottom, 50)
            }
            .overlay {
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: geometry.size.width * viewModel.progress, height: 2)
                    .position(
                        x: geometry.size.width * viewModel.progress / 2,
                        y: geometry.size.height - 1
                    )
                    .opacity(viewModel.isPaused ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: viewModel.playbackState) { _, _ in
            viewModel.onPlaybackStateChange()
        }
        .onChange(of: scenePhase) { _, phase in
            viewModel.onScenePhaseChange(isBackgroundOrInactive: phase == .background || phase == .inactive)
        }
    }
}

#Preview {
    NavigationStack {
        ReadingView(article: Article(url: URL(string: "https://example.com")!, title: "Sample", content: "This is a sample text for testing the speed reading view."))
    }
    .modelContainer(for: Article.self, inMemory: true)
}
