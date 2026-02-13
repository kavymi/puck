# Puck

> *"I find myself surprisingly comfortable in this world."* — Puck, the Faerie Dragon

A native macOS video downloader built with SwiftUI, themed after **Puck** from Dota 2 — the mischievous Faerie Dragon who drifts between the planes of dream and reality. Like Puck's Illusory Orb, this app phases your media across the internet and into your local realm at maximum speed.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

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
- **Settings** — output folder, parallel streams, codec, audio quality, sample rate, bit depth
- **Self-contained DMG** — bundles yt-dlp and ffmpeg so end users don't need Homebrew

## Screenshots

<!-- Add screenshots here -->
<!-- ![Main Window](docs/screenshots/main.png) -->
<!-- ![Settings](docs/screenshots/settings.png) -->

## Installation

### Download DMG (recommended)

1. Download the latest `Puck-x.x.x.dmg` from [Releases](../../releases)
2. Open the DMG and drag **Puck** to your Applications folder
3. Right-click → **Open** the first time (required for unsigned apps)

The DMG includes bundled `yt-dlp` and `ffmpeg` — no additional installs needed.

### Build from Source

**Requirements:**
- macOS 14.0+
- Xcode 15.4+

```bash
git clone https://github.com/kavyrattana/puck.git
cd puck
open Puck.xcodeproj
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

Output: `Puck-2.0.0.dmg`

## Usage

1. Open **Puck**
2. Paste one or more URLs (one per line), or drag & drop a link into the window
3. Click **Download** — parallel downloads begin and auto-convert when complete
4. Open **Settings** (⌘,) to configure:
   - **Download Mode** — Video + Audio or Audio Only
   - **Video Codec** — ProRes 422 Proxy / LT / HQ
   - **Audio Settings** — sample rate, bit depth, format
   - **Output folder**, parallel streams, and more

## How It Works

| Puck's Ability | What It Does |
|---|---|
| **Illusory Orb** | Fetches playlist metadata at the speed of thought |
| **Phase Shift** | Parallel downloads phase your media into existence |
| **Waning Rift** | Concurrent yt-dlp fragments tear through bandwidth |
| **Dream Coil** | Binds all playlist items and processes them together |

### Download Pipeline

```
URL → yt-dlp (download) → ffmpeg (convert to ProRes/audio) → Output folder
```

- **yt-dlp** handles downloading with concurrent fragments, retries, and chunked HTTP
- **ffmpeg** converts to ProRes 422 `.mov` (video) or the selected audio format
- Both binaries are bundled in the app or discovered from Homebrew/system PATH

## Architecture

```
Puck/
├── PuckApp.swift                     # App entry point
├── Models/
│   ├── DownloadItem.swift            # Download item model & URL classification
│   └── AppSettings.swift             # Persisted settings (UserDefaults)
├── Managers/
│   ├── BinaryManager.swift           # Locates & manages yt-dlp/ffmpeg binaries
│   ├── DownloadManager.swift         # yt-dlp process with progress parsing
│   └── ConversionManager.swift       # ffmpeg ProRes/audio conversion with progress
├── ViewModels/
│   └── DownloadViewModel.swift       # Download orchestration via TaskGroup
├── Views/
│   ├── ContentView.swift             # Main window
│   ├── DownloadItemRow.swift         # Per-item progress row
│   └── SettingsView.swift            # Settings panel
├── Assets.xcassets/                  # App icon & accent color
└── Puck.entitlements                 # Network & file access entitlements
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

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — the backbone of all downloads
- [ffmpeg](https://ffmpeg.org/) — powers all media conversion
- [Dota 2](https://www.dota2.com/) — for the Faerie Dragon that inspired this app's name and theme
