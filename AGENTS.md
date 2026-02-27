# AGENTS.md — AI Agent Guidelines for Pluck

This document provides instructions for AI coding agents (Claude, Cursor, Copilot, Windsurf, etc.) working on the Pluck codebase.

## Quick Reference

| Aspect | Detail |
|---|---|
| **Language** | Swift 5.9+ |
| **Framework** | SwiftUI (macOS 14.0+) |
| **Build System** | Xcode 15.4+ (`.xcodeproj`, no SPM) |
| **Dependencies** | Zero third-party Swift packages |
| **Concurrency** | Swift Concurrency (`actor`, `async/await`, `TaskGroup`) |
| **State Management** | `@Observable` (Observation framework) |
| **External Binaries** | `yt-dlp`, `ffmpeg` (spawned as child processes) |

## Architecture

### Layer Responsibilities

- **`Models/`** — Pure data types, enums, and the `AppSettings` singleton. No business logic beyond persistence.
- **`Managers/`** — Actor-isolated business logic. `DownloadManager` and `ConversionManager` spawn and manage child processes. `BinaryManager` is a static struct for binary discovery. `NLEIntegrationManager` handles auto-import into video editors (Premiere Pro, DaVinci Resolve, Final Cut Pro, After Effects).
- **`ViewModels/`** — `@MainActor` orchestration layer. `DownloadViewModel` coordinates downloads via `TaskGroup` and updates UI state.
- **`Views/`** — SwiftUI views. Thin presentation layer that binds to the view model.

### Concurrency Model

```
MainActor (UI)          Actor (DownloadManager)       Actor (ConversionManager)
     │                         │                              │
     ├─ DownloadViewModel      ├─ Spawns yt-dlp Process       ├─ Spawns ffmpeg Process
     │  (TaskGroup)            ├─ Parses stdout/stderr        ├─ Parses progress output
     │                         └─ Returns file path           └─ Returns converted path
     │
     ├─ Updates DownloadItem status/progress on MainActor
     └─ NLEIntegrationManager (auto-import into video editors)
```

Progress callbacks cross actor boundaries via `@Sendable` closures and `Task { @MainActor in ... }`.

### Binary Discovery Order

`BinaryManager.locate()` searches in this order:
1. App bundle `Resources/bin/` directory
2. App bundle `MacOS/` directory
3. `/opt/homebrew/bin/` (Apple Silicon Homebrew)
4. `/usr/local/bin/` (Intel Homebrew)
5. `/usr/bin/` (system)
6. `which` fallback

## Coding Conventions

### Must Follow
- **Swift Concurrency only** — use `actor`, `async/await`, `TaskGroup`. Never introduce GCD (`DispatchQueue`).
- **`@Observable`** — never use `ObservableObject`/`@Published`/`@StateObject`.
- **`Bindable()`** — for two-way bindings in SwiftUI views (e.g., `Bindable(settings).videoCodec`).
- **`Sendable` compliance** — all types crossing concurrency boundaries must be `Sendable`.
- **No third-party packages** — the project is intentionally dependency-free.
- **`// MARK: -` comments** — use for section organization in all files.

### Animation Standards
- **Interactive animations**: `.spring(duration: 0.3–0.5, bounce: 0.15–0.3)`
- **State transitions**: `.easeInOut(duration: 0.2–0.3)`
- **SF Symbol effects**: `.symbolEffect(.bounce)`, `.symbolEffect(.pulse)`
- **Numeric content**: `.contentTransition(.numericText())`
- **List items**: `.transition(.asymmetric(insertion:removal:))`

### Theme Colors
- **Download/cyan**: `Color(red: 0.4, green: 0.8, blue: 1.0)`
- **Conversion/purple**: `Color(red: 0.6, green: 0.5, blue: 1.0)`
- **Gradient**: cyan → purple (used in header, empty state, drop overlay)

## Common Modification Patterns

### Adding a New Setting
1. Add property to `AppSettings` with `didSet { save() }`
2. Load in `AppSettings.init()` from `UserDefaults`
3. Persist in `AppSettings.save()`
4. Add picker/toggle in `SettingsView`
5. If needed for conversion, add to `ConversionManager.ConversionSettings`

### Adding a New Audio/Video Format
1. Add case to the relevant enum in `AppSettings.swift`
2. Add ffmpeg arguments in `ConversionManager.convert()`
3. Update file extension handling in `DownloadManager.downloadAndGetPath()`

### Modifying the Download Pipeline
1. `DownloadManager` handles all yt-dlp interaction
2. Arguments are constructed per-mode in `download()` / `downloadAndGetPath()`
3. Progress is parsed from stdout via regex (`parsePercent`, `extractPath`)
4. File paths come from `--print after_move:filepath` or fallback directory scan

### Adding a New NLE Editor
1. Add case to `NLEApp` enum in `NLEIntegrationManager.swift`
2. Add `displayName`, `iconName`, `bundleIdentifier`, and `appSearchPaths`
3. Implement import logic in `NLEIntegrationManager.importFile()`

## Testing

There are no automated tests currently. Manual testing checklist:
- [ ] Single video download (YouTube, Vimeo)
- [ ] Playlist download with concurrent items
- [ ] Audio-only mode (each format: MP3, FLAC, WAV, M4A, Opus, OGG)
- [ ] Video + Audio mode with ProRes conversion (Proxy, LT, HQ)
- [ ] Drag-and-drop URL
- [ ] Cancel in progress
- [ ] Retry failed download
- [ ] Settings persistence across app restart
- [ ] Binary detection (bundled vs Homebrew vs missing)
- [ ] NLE auto-import (Premiere Pro, DaVinci Resolve, Final Cut Pro, After Effects)

## Files You Should Not Modify Without Care

- **`BinaryManager.swift`** — binary discovery order matters for DMG vs dev environments
- **`NLEIntegrationManager.swift`** — AppleScript/OSA integration with video editors
- **`build_dmg_swift.sh`** — DMG packaging script, changes affect distribution
- **`Pluck.entitlements`** — network and file access permissions
