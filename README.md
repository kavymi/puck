<div align="center">

# Pluck

A native macOS video downloader built with SwiftUI. Pluck grabs your media from the web and pulls it into your local library at maximum speed.

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift&logoColor=white)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![No Dependencies](https://img.shields.io/badge/Dependencies-Zero-purple)]()

</div>

---

## Features

- **Parallel downloads** — configurable concurrency (1–8 simultaneous streams)
- **Paste URL or drag & drop** — auto-detects single videos and playlists
- **Highest quality download** — powered by [yt-dlp](https://github.com/yt-dlp/yt-dlp) with concurrent fragment downloading
- **ProRes 422 conversion** — choose between Proxy, LT, or HQ profiles via [ffmpeg](https://ffmpeg.org/)
- **Audio-only mode** — extract audio in MP3, FLAC, WAV, M4A, Opus, or OGG
- **Playlist support** — auto-creates folder per playlist, concurrent item processing
- **Progress tracking** — separate download + conversion progress bars per item
- **Queue management** — batch URLs, retry failed, cancel in progress
- **Polished UI** — smooth spring animations, symbol effects, and a clean gradient theme
- **Settings** — output folder, parallel streams, codec, audio quality, sample rate, bit depth
- **NLE auto-import** — automatically import into Premiere Pro, DaVinci Resolve, Final Cut Pro, or After Effects
- **Self-contained DMG** — bundles yt-dlp and ffmpeg so end users don't need Homebrew
- **Zero dependencies** — pure SwiftUI + Foundation, no third-party Swift packages

## Installation

### Download DMG (Recommended)

1. Download the latest **`Pluck-2.0.0.dmg`** from [Releases](../../releases)
2. Open the DMG and drag **Pluck** to your Applications folder
3. Right-click → **Open** the first time (required for unsigned apps)

> The DMG includes bundled `yt-dlp` and `ffmpeg` — no additional installs needed.

### Build from Source

**Requirements:** macOS 14.0+ · Xcode 15.4+

```bash
git clone https://github.com/kavymi/pluck.git
cd pluck
open Pluck.xcodeproj
```

Press **⌘R** to build and run. The app auto-detects `yt-dlp` and `ffmpeg` from Homebrew or the system PATH.

**Optional:** Install yt-dlp and ffmpeg locally for development:

```bash
brew install yt-dlp ffmpeg
```

### Build DMG Installer

```bash
chmod +x build_dmg_swift.sh
./build_dmg_swift.sh
```

This will:
1. Build a Release archive via `xcodebuild`
2. Extract the `.app` bundle
3. Download the standalone `yt-dlp` binary and bundle it with `ffmpeg`/`ffprobe`
4. Package into a `.dmg` with drag-to-Applications install

Output: `Pluck-2.0.0.dmg`

## Usage

1. Open **Pluck**
2. Paste one or more URLs (one per line), or drag & drop a link into the window
3. Click **Download** — parallel downloads begin and auto-convert when complete
4. Open **Settings** (⌘,) to configure:
   - **Download Mode** — Video + Audio or Audio Only
   - **Video Codec** — ProRes 422 Proxy / LT / HQ
   - **Audio Settings** — sample rate, bit depth, format
   - **Output folder**, parallel streams, and more

## How It Works

### Download Pipeline

```
URL → yt-dlp (download) → ffmpeg (convert to ProRes/audio) → Output folder
```

- **yt-dlp** handles downloading with concurrent fragments, retries, and chunked HTTP
- **ffmpeg** converts to ProRes 422 `.mov` (video) or the selected audio format
- Both binaries are bundled in the app or discovered from Homebrew/system PATH

## Architecture

```
Pluck/
├── PluckApp.swift                    # App entry point
├── Models/
│   ├── DownloadItem.swift            # Download item model & URL classification
│   └── AppSettings.swift             # Persisted settings (UserDefaults)
├── Managers/
│   ├── BinaryManager.swift           # Locates & manages yt-dlp/ffmpeg binaries
│   ├── DownloadManager.swift         # yt-dlp process with progress parsing
│   ├── ConversionManager.swift       # ffmpeg ProRes/audio conversion with progress
│   └── NLEIntegrationManager.swift   # Auto-import into video editors
├── ViewModels/
│   └── DownloadViewModel.swift       # Download orchestration via TaskGroup
├── Views/
│   ├── ContentView.swift             # Main window
│   ├── DownloadItemRow.swift         # Per-item progress row
│   └── SettingsView.swift            # Settings panel
├── Assets.xcassets/                  # App icon & accent color
└── Pluck.entitlements                 # Network & file access entitlements
```

### Key Design Decisions

- **Swift Concurrency** — all download/conversion work uses `actor` isolation and `TaskGroup` for safe parallelism
- **No third-party Swift dependencies** — pure SwiftUI + Foundation
- **Process-based architecture** — spawns `yt-dlp` and `ffmpeg` as child processes with stdout/stderr parsing for progress
- **Binary bundling** — standalone `yt-dlp_macos` binary (no Python required) + Homebrew ffmpeg

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## AI Agent Guidelines

This project includes configuration files for AI coding assistants:

- **`AGENTS.md`** — comprehensive guidelines for all AI agents (architecture, conventions, patterns)
- **`CLAUDE.md`** — Claude Code–specific context and build instructions
- **`.cursorrules`** — Cursor IDE rules

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — the backbone of all downloads
- [ffmpeg](https://ffmpeg.org/) — powers all media conversion
