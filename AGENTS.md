# Slit

Speed reading app for iOS.

The app lets you import articles from URLs or via iOS Share Extension. Articles are displayed in RSVP (Rapid Serial Visual Presentation) format — word-by-word display with dynamic pacing that accounts for word complexity and reading ramp-up/ramp-down.

The app tracks reading progress and completion status across sessions.

Targeting iOS 18+.

## Stack

- Swift as a programming language
- SwiftUI as a layout framework
- SwiftData as a persistence layer
- Swift Testing as a test runner

## Structure

- `Slit/SlitApp.swift`: app entry point, SwiftData container setup
- `Slit/ContentView.swift`: root-level navigation stack
- `Slit/ArticleListView.swift`: article list UI with CRUD operations
- `Slit/ReadingView.swift`: speed reading display with gesture control
- `Slit/Article.swift`: SwiftData model with reading progress tracking
- `Slit/ArticleImporter.swift`: URL fetch and article content extraction
- `Slit/HTMLTextExtractor.swift`: HTML-to-text with word boundary preservation
- `Slit/ReadingPacer.swift`: dynamic WPM calculation based on word complexity
- `Slit/WordSplitter.swift`: text-to-word array splitting
- `Slit/URLNormalizer.swift`: URL canonicalization for deduplication
- `Slit/SharedURLManager.swift`: App Group UserDefaults for Share Extension
- `ShareExtension/`: iOS Share sheet integration
- `SlitTests/`: unit tests (actively maintained)

The project uses SwiftUI + SwiftData patterns. Persistent data is stored in SwiftData models, and views use `@Query` and `@Environment(\.modelContext)` to access and modify data.

## Targets

- **Slit**: main app target
- **SlitTests**: unit tests
- **ShareExtension**: iOS share sheet integration for importing articles from other apps

## Build & Commands

- Build: `xcodebuild -scheme Slit -destination 'generic/platform=iOS' build`
- Unit tests: `xcodebuild -scheme Slit -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:SlitTests`
- Run on device: Use `xcrun devicectl list devices` to get device UUID, then `xcrun devicectl device install app --device <UUID> <BUILT_PRODUCTS_DIR>/Slit.app && xcrun devicectl device process launch --device <UUID> DestinerLabs.Slit`

## Dependencies

Uses Swift Package Manager.

- **Reeeed** (https://github.com/nate-parrott/reeeed): article content extraction using Mercury and Readability extractors

## Code Style

- Prefer declarative programming
- Don't use "legacy" frameworks like Combine and UIKit