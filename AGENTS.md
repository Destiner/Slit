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

## Architecture

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

## Targets

- **Slit**: main app target
- **SlitTests**: unit tests
- **ShareExtension**: iOS share sheet integration for importing articles from other apps

## Build & Commands

- Build: `xcodebuild -scheme Slit -destination 'generic/platform=iOS' build`
- Unit tests: `xcodebuild -scheme Slit -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:SlitTests`
- Run on device: Use `xcrun devicectl list devices` to get device UUID, then `xcrun devicectl device install app --device <UUID> <BUILT_PRODUCTS_DIR>/Slit.app && xcrun devicectl device process launch --device <UUID> DestinerLabs.Slit`

## Release

See [docs/release.md](docs/release.md) for App Store release instructions.

## Dependencies

Uses Swift Package Manager.

- **Reeeed** (https://github.com/nate-parrott/reeeed): article content extraction using Mercury and Readability extractors

## Code Style

- Prefer declarative programming
- Don't use "legacy" frameworks like Combine and UIKit
- Run `swiftformat .` before committing to format all Swift files