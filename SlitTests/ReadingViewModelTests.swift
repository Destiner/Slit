//
//  ReadingViewModelTests.swift
//  SlitTests
//
//  Created by Timur Badretdinov on 31/01/2026.
//

import Foundation
@testable import Slit
import Testing

struct ReadingViewModelTests {
    private func makeViewModel() -> ReadingViewModel {
        let article = Article(url: URL(string: "https://example.com")!, title: "Test", content: "One two three four five six seven eight nine ten")
        return ReadingViewModel(article: article)
    }

    // MARK: - Background while unpaused (swipe gesture pauses it)

    @Test func swipeWhileUnpausedPausesAndTapResumes() async throws {
        let vm = makeViewModel()

        // Start playing
        vm.playbackState = .playing

        // User swipes to close - the swipe gesture touches the screen first
        vm.handlePressStart()
        // This pauses the reading
        #expect(vm.isPaused == true)

        // App goes to background before gesture ends (user swiped away)
        vm.onScenePhaseChange(isBackgroundOrInactive: true)

        // Simulate returning to foreground
        vm.onScenePhaseChange(isBackgroundOrInactive: false)

        // Should still be paused
        #expect(vm.isPaused == true)

        // Wait for the spurious gesture guard to expire
        try await Task.sleep(for: .milliseconds(150))

        // Tap to resume
        vm.handlePressStart()
        vm.handlePressEnd()

        #expect(vm.isPaused == false)
    }

    // MARK: - Background while paused

    @Test func backgroundWhilePausedStaysPaused() async throws {
        let vm = makeViewModel()

        // Already paused (default state)
        #expect(vm.isPaused == true)

        // Simulate going to background
        vm.onScenePhaseChange(isBackgroundOrInactive: true)

        // Simulate returning to foreground
        vm.onScenePhaseChange(isBackgroundOrInactive: false)

        // Should still be paused
        #expect(vm.isPaused == true)

        // Wait for the spurious gesture guard to expire
        try await Task.sleep(for: .milliseconds(150))

        // Tap to resume
        vm.handlePressStart()
        vm.handlePressEnd()

        #expect(vm.isPaused == false)
    }
}
