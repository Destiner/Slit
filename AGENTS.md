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

Feature-based MVVM. Each feature has `Models/`, `ViewModels/`, `Views/`, `DataSources/`, and `Utilities/` subdirectories as needed.

- `Slit/Features/Articles/` — article list and management
- `Slit/Features/Reading/` — speed reading display
- `Slit/Shared/` — reusable components across features
- `ShareExtension/` — iOS Share sheet integration
- `SlitTests/` — unit tests

### MVVM Pattern

- **Views**: SwiftUI views with `@State private var viewModel`
- **ViewModels**: `@Observable` classes containing business logic and state
- **DataSources**: Handle SwiftData context operations, injected into ViewModels
- **Models**: SwiftData `@Model` classes for persistence

Don't pass viewmodels to subviews — pass specific data (down) and callbacks (up).

## Targets

- **Slit**: main app target
- **SlitTests**: unit tests
- **ShareExtension**: iOS share sheet integration for importing articles from other apps

## Commands

- `xcodebuild -scheme Slit -destination 'generic/platform=iOS' build` - Build the app
- `xcodebuild -scheme Slit -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:SlitTests` - Run unit tests
- `swiftformat .` - Format all Swift files
- `asc` - App Store Connect CLI

## Dependencies

Uses Swift Package Manager.

- **Reeeed** (https://github.com/nate-parrott/reeeed): article content extraction using Mercury and Readability extractors

## Patterns

- Prefer declarative programming
- Don’t use “legacy” frameworks like Combine and UIKit

## SwiftUI APIs

### Toolbar

The app heavily uses `.toolbar` and `ToolbarItem` throughout the app as a go-to way to navigate between screens and toggle high-level views.

### Navigation

Prefer using `NavigationStack` and `NavigationLink` for all navigation activities.

### Liquid Glass

The app relies on some cutting-edge APIs, only available on iOS/macOS 26. Specifically, the app uses “liquid glass” — a new rendering mode for common UI controls (buttons, sheets, popups). There is a fallback available for toolbar item labels and `buttonStyle(.glass)` modifier.
