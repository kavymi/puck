# CLAUDE.md — Pluck Development Guide

This file provides context for Claude Code (claude.ai/code) when working on this codebase.

## Project Overview

Pluck is a native macOS video/audio downloader built with SwiftUI. It wraps `yt-dlp` for downloading and `ffmpeg` for ProRes/audio conversion, orchestrating parallel downloads via Swift Concurrency.

## Build & Run

```bash
# Open in Xcode
open Pluck.xcodeproj

# Build and run: ⌘R in Xcode
# Requires: macOS 14.0+, Xcode 15.4+

# Optional local dependencies (auto-detected from Homebrew/system PATH):
brew install yt-dlp ffmpeg

# Build DMG installer:
chmod +x build_dmg_swift.sh
./build_dmg_swift.sh
```

There is no Swift Package Manager — the project uses Xcode's native build system with zero third-party Swift dependencies.

## Architecture

```
Pluck/
├── PluckApp.swift                    # @main App entry point
├── Models/
│   ├── DownloadItem.swift            # DownloadItem model, DownloadStatus enum, URLType classifier
│   └── AppSettings.swift             # @Observable singleton, UserDefaults persistence, all enums
├── Managers/
│   ├── BinaryManager.swift           # Static binary locator (bundle → Homebrew → system → `which`)
│   ├── DownloadManager.swift         # Actor: yt-dlp process spawning, progress parsing, playlist info
│   ├── ConversionManager.swift       # Actor: ffmpeg conversion, progress parsing, duration detection
│   └── NLEIntegrationManager.swift   # Auto-import into video editors (Premiere, Resolve, FCP, AE)
├── ViewModels/
│   └── DownloadViewModel.swift       # @Observable @MainActor: orchestrates TaskGroup parallelism
└── Views/
    ├── ContentView.swift             # Main window, drag-and-drop, URL input, queue, log
    ├── DownloadItemRow.swift         # Per-item row with progress bars and status icons
    └── SettingsView.swift            # Inline settings panel
```

### Key Patterns

- **Swift Concurrency everywhere** — `actor` for managers, `@MainActor` for view model, `TaskGroup` for parallel downloads
- **`@Observable` (not `ObservableObject`)** — uses the Observation framework (macOS 14+)
- **Process-based architecture** — spawns `yt-dlp`/`ffmpeg` as child `Process` instances, parses stdout/stderr for progress
- **Binary discovery** — `BinaryManager` checks app bundle `Resources/bin/`, then Homebrew paths, then `which`
- **No third-party Swift dependencies** — pure SwiftUI + Foundation

### Data Flow

```
User pastes URL → DownloadViewModel.addURLs() → DownloadViewModel.startProcessing()
  → TaskGroup spawns up to N concurrent tasks
    → DownloadManager.downloadAndGetPath() (yt-dlp process)
    → ConversionManager.convert() (ffmpeg process)
  → DownloadItem status/progress updated on @MainActor
```

## Code Style

- Use Swift Concurrency (`actor`, `async/await`, `TaskGroup`) — never GCD for new code
- Views in `Views/`, business logic in `Managers/` and `ViewModels/`
- Use `@Observable` for reactive state, `Bindable()` for two-way bindings in views
- Prefer `Sendable` types across concurrency boundaries
- MARK comments for section organization (`// MARK: - Section Name`)
- Animations use `spring()` for interactive elements, `easeInOut` for state transitions
- Theme colors: cyan `(0.4, 0.8, 1.0)` for download, purple `(0.6, 0.5, 1.0)` for conversion

## Common Tasks

### Adding a new setting
1. Add property with `didSet { save() }` to `AppSettings`
2. Add persistence in `init()` and `save()`
3. Add UI in `SettingsView`
4. Reference from `DownloadViewModel` or managers as needed

### Adding a new download source
1. Add case to `URLType` enum in `DownloadItem.swift`
2. Update `URLType.classify()` pattern matching
3. yt-dlp handles most sites automatically — usually no manager changes needed

### Modifying conversion pipeline
1. Update `ConversionManager.ConversionSettings` if new options needed
2. Update ffmpeg argument construction in `ConversionManager.convert()`
3. Update `ConversionSettings.from()` to map from `AppSettings`

### Adding a new NLE editor
1. Add case to `NLEApp` enum in `NLEIntegrationManager.swift`
2. Add `displayName`, `iconName`, `bundleIdentifier`, and `appSearchPaths`
3. Implement import logic in `NLEIntegrationManager.importFile()`
