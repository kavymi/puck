# Contributing to Pluck

Thanks for your interest in contributing! Pluck is a small, focused macOS app and we welcome improvements of all kinds.

## Getting Started

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/pluck.git
   cd pluck
   ```
3. **Open** `Pluck.xcodeproj` in Xcode 15.4+
4. **Install** dependencies for local development:
   ```bash
   brew install yt-dlp ffmpeg
   ```
5. **Build & Run** with ⌘R

## Making Changes

1. Create a new branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your changes
3. Test thoroughly — build the app, try downloading a video, and verify conversion works
4. Commit with a clear message:
   ```bash
   git commit -m "Add: brief description of your change"
   ```

## Commit Message Format

Use a short prefix to categorize your commit:

- `Add:` — new feature or functionality
- `Fix:` — bug fix
- `Update:` — change to existing functionality
- `Refactor:` — code restructuring without behavior change
- `Docs:` — documentation only
- `Build:` — changes to build scripts or configuration

## Pull Requests

1. Push your branch to your fork
2. Open a Pull Request against `main`
3. Describe **what** you changed and **why**
4. Include steps to test your change if applicable

### PR Checklist

- [ ] Builds without errors or warnings
- [ ] Tested on macOS 14.0+
- [ ] No third-party Swift dependencies added (we aim to stay dependency-free)
- [ ] Settings changes persist correctly via UserDefaults
- [ ] Download and conversion pipelines still work end-to-end

## Code Style

- Follow existing Swift conventions in the codebase
- Use Swift Concurrency (`actor`, `async/await`, `TaskGroup`) for concurrent work
- Keep views in `Views/`, business logic in `Managers/` and `ViewModels/`
- Use `@Observable` for reactive state (not `ObservableObject`)
- Prefer `Sendable` types for data passed across concurrency boundaries

## Architecture Overview

```
User Action → DownloadViewModel → DownloadManager (yt-dlp) → ConversionManager (ffmpeg) → Output
```

- **`BinaryManager`** — locates yt-dlp/ffmpeg from bundle or system
- **`DownloadManager`** — actor that spawns yt-dlp processes and parses progress
- **`ConversionManager`** — actor that spawns ffmpeg processes and parses progress
- **`DownloadViewModel`** — orchestrates parallel downloads via `TaskGroup`
- **`AppSettings`** — singleton with `UserDefaults` persistence

## Reporting Issues

- Use [GitHub Issues](../../issues) to report bugs or request features
- Include your macOS version and steps to reproduce
- Paste any error messages from the app's log panel

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
