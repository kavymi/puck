# Changelog

All notable changes to Puck will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - 2025-02-12

### Added
- **Download Mode selector** — choose between Video + Audio or Audio Only
- **ProRes 422 codec options** — Proxy, LT, and HQ profiles
- **Audio format picker** — MP3, FLAC, WAV, M4A, Opus, OGG (available in Audio Only mode)
- **Standalone yt-dlp bundling** — DMG now includes a self-contained yt-dlp binary (no Python required)
- **Quarantine attribute removal** — bundled binaries are automatically de-quarantined at runtime
- Open source release with MIT license, contributing guidelines, and documentation

### Changed
- Video codec options simplified to ProRes 422 family only (Proxy / LT / HQ)
- Video format locked to `.mov` (all ProRes outputs)
- Build script downloads standalone `yt-dlp_macos` instead of copying local Python script
- Settings UI conditionally shows video/audio sections based on download mode

### Removed
- ProRes 4444 codec option
- H.264 codec option
- Copy (no re-encode) codec option
- Video Only download mode
- Legacy Python app (`app/`, `main.py`, `requirements.txt`)

## [1.0.0] - 2025-01-01

### Added
- Initial release as native macOS SwiftUI app
- Parallel downloads with configurable concurrency (1–8 streams)
- URL paste and drag-and-drop support
- Playlist detection and batch downloading
- ProRes 4444 and H.264 conversion via ffmpeg
- Progress tracking with per-item download and conversion bars
- Settings panel for output folder, codec, audio quality
- Queue management with retry and cancel
- yt-dlp and ffmpeg binary auto-detection from Homebrew and system PATH
- DMG build script with binary bundling
