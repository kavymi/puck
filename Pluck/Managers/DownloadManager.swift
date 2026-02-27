import Foundation

/// Manages yt-dlp downloads with progress parsing via stdout/stderr.
actor DownloadManager {
    
    private var activeProcesses: Set<Process> = []
    private var isCancelled = false
    
    // MARK: - Public API
    
    struct VideoInfo {
        let title: String
        let filePath: String
        let isPlaylist: Bool
        let playlistTitle: String?
        let entries: [PlaylistEntry]
    }
    
    struct PlaylistEntry {
        let url: String
        let title: String
        let index: Int
    }
    
    /// Fetch metadata for a URL without downloading.
    /// Uses --print with specific fields for fast playlist enumeration instead of slow --dump-json.
    func fetchInfo(url: String) async throws -> VideoInfo {
        let ytdlp = try BinaryManager.ytdlpURL()
        
        // First, check if this is a playlist by using --flat-playlist --print
        // This is much faster than --dump-json which resolves full metadata per entry
        let args = [
            "--flat-playlist",
            "--print", "%(playlist_title)s\t%(id)s\t%(title)s\t%(url)s",
            "--no-warnings",
            "--socket-timeout", "30",
            url
        ]
        
        let output = try await runProcess(executable: ytdlp, arguments: args, parseProgress: false)
        let lines = output.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            return VideoInfo(title: "Unknown", filePath: "", isPlaylist: false, playlistTitle: nil, entries: [])
        }
        
        // If only one line, it could be a single video or a 1-item playlist
        // Check if the playlist_title field is "NA" (yt-dlp outputs "NA" for non-playlist URLs)
        if lines.count == 1 {
            let parts = lines[0].components(separatedBy: "\t")
            let playlistTitle = parts.count > 0 ? parts[0] : "NA"
            let title = parts.count > 2 ? parts[2] : "Unknown"
            
            if playlistTitle == "NA" || playlistTitle.isEmpty {
                // Single video, not a playlist
                return VideoInfo(
                    title: title,
                    filePath: "",
                    isPlaylist: false,
                    playlistTitle: nil,
                    entries: []
                )
            }
        }
        
        // Multiple lines = playlist
        var entries: [PlaylistEntry] = []
        var playlistTitle = "Playlist"
        
        for (i, line) in lines.enumerated() {
            let parts = line.components(separatedBy: "\t")
            if parts.count >= 3 {
                if parts[0] != "NA" && !parts[0].isEmpty {
                    playlistTitle = parts[0]
                }
                let videoID = parts[1]
                let title = parts[2]
                let videoURL = parts.count > 3 && !parts[3].isEmpty && parts[3] != "NA"
                    ? parts[3]
                    : "https://www.youtube.com/watch?v=\(videoID)"
                entries.append(PlaylistEntry(url: videoURL, title: title, index: i))
            }
        }
        
        return VideoInfo(
            title: playlistTitle,
            filePath: "",
            isPlaylist: true,
            playlistTitle: playlistTitle,
            entries: entries
        )
    }
    
    /// Download a single video to the specified directory. Returns the path to the downloaded file.
    func download(
        url: String,
        to outputDir: URL,
        mode: DownloadMode = .both,
        audioFormat: AudioFormat = .mp3,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> String {
        isCancelled = false
        let ytdlp = try BinaryManager.ytdlpURL()
        
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let outputTemplate = outputDir.appendingPathComponent("%(title)s.%(ext)s").path
        
        var args: [String]
        switch mode {
        case .audioOnly:
            args = [
                "-f", "bestaudio[ext=m4a]/bestaudio/best",
                "-x",
                "--audio-format", audioFormat.rawValue,
                "--audio-quality", "0",
            ]
        case .both:
            args = [
                "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best",
                "--merge-output-format", "mp4",
            ]
        }
        
        args += [
            "-o", outputTemplate,
            "--newline",
            "--no-warnings",
            "--no-playlist",
            "--progress-template", "download:%(progress._percent_str)s %(progress._speed_str)s %(progress._eta_str)s",
            "--retries", "10",
            "--fragment-retries", "10",
            "--socket-timeout", "15",
            "--concurrent-fragments", "4",
            "--buffer-size", "16K",
            "--http-chunk-size", "10M",
        ]
        
        // Add ffmpeg location if available
        if let ffmpeg = try? BinaryManager.ffmpegURL() {
            args.append(contentsOf: ["--ffmpeg-location", ffmpeg.deletingLastPathComponent().path])
        }
        
        args.append(url)
        
        let filePath = try await runProcessWithProgress(
            executable: ytdlp,
            arguments: args,
            progress: progress
        )
        
        return filePath
    }
    
    /// Download a single video and return the actual filename.
    /// Uses --print to get the filepath in a single yt-dlp invocation (no separate metadata call).
    func downloadAndGetPath(
        url: String,
        to outputDir: URL,
        mode: DownloadMode = .both,
        audioFormat: AudioFormat = .mp3,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> String {
        isCancelled = false
        let ytdlp = try BinaryManager.ytdlpURL()
        
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let outputTemplate = outputDir.appendingPathComponent("%(title)s.%(ext)s").path
        
        // Single invocation: download + print filepath
        // --no-playlist ensures URLs with list= params only download the single video
        var downloadArgs: [String]
        switch mode {
        case .audioOnly:
            downloadArgs = [
                "-f", "bestaudio[ext=m4a]/bestaudio/best",
                "-x",
                "--audio-format", audioFormat.rawValue,
                "--audio-quality", "0",
            ]
        case .both:
            downloadArgs = [
                "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best",
                "--merge-output-format", "mp4",
            ]
        }
        
        downloadArgs += [
            "-o", outputTemplate,
            "--newline",
            "--no-warnings",
            "--no-playlist",
            "--print", "after_move:filepath",
            "--progress-template", "download:%(progress._percent_str)s %(progress._speed_str)s %(progress._eta_str)s",
            "--retries", "10",
            "--fragment-retries", "10",
            "--socket-timeout", "15",
            "--concurrent-fragments", "4",
            "--buffer-size", "16K",
            "--http-chunk-size", "10M",
        ]
        
        if let ffmpeg = try? BinaryManager.ffmpegURL() {
            downloadArgs.append(contentsOf: ["--ffmpeg-location", ffmpeg.deletingLastPathComponent().path])
        }
        
        downloadArgs.append(url)
        
        let lastFilePath = try await runProcessWithProgress(
            executable: ytdlp,
            arguments: downloadArgs,
            progress: progress
        )
        
        // The --print output is captured as the last non-progress line
        if !lastFilePath.isEmpty && FileManager.default.fileExists(atPath: lastFilePath) {
            return lastFilePath
        }
        
        // Fallback: find most recently modified file of the expected type in output dir
        let expectedExtensions: Set<String>
        switch mode {
        case .audioOnly: expectedExtensions = ["wav", "m4a", "mp3", "opus", "ogg", "flac"]
        case .both: expectedExtensions = ["mp4", "mkv", "webm", "mov"]
        }
        let contents = try FileManager.default.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: [.contentModificationDateKey])
        let mp4Files = contents.filter { expectedExtensions.contains($0.pathExtension.lowercased()) }
        if let newest = mp4Files.sorted(by: {
            let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return d1 > d2
        }).first {
            return newest.path
        }
        
        return outputTemplate.replacingOccurrences(of: "%(title)s.%(ext)s", with: "")
    }
    
    func cancel() {
        isCancelled = true
        for process in activeProcesses {
            process.terminate()
        }
        activeProcesses.removeAll()
    }
    
    // MARK: - Private
    
    private func runProcess(executable: URL, arguments: [String], parseProgress: Bool) async throws -> String {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.environment = ProcessInfo.processInfo.environment
        
        activeProcesses.insert(process)
        
        return try await withCheckedThrowingContinuation { continuation in
            var outputData = Data()
            
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    outputData.append(data)
                }
            }
            
            process.terminationHandler = { [weak self] proc in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                Task { await self?.removeProcess(proc) }
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: NSError(
                        domain: "DownloadManager",
                        code: Int(proc.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: errStr.prefix(500).description]
                    ))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func removeProcess(_ process: Process) {
        activeProcesses.remove(process)
    }
    
    private func runProcessWithProgress(
        executable: URL,
        arguments: [String],
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> String {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.environment = ProcessInfo.processInfo.environment
        
        activeProcesses.insert(process)
        
        return try await withCheckedThrowingContinuation { continuation in
            var lastFilePath = ""
            var lastProgressUpdate = CFAbsoluteTimeGetCurrent()
            let progressThrottle: CFAbsoluteTime = 0.15
            
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
                
                for subline in line.components(separatedBy: .newlines) where !subline.isEmpty {
                    let trimmed = subline.trimmingCharacters(in: .whitespaces)
                    
                    // Parse progress: "download: 45.2% 5.2MiB/s 00:12"
                    if trimmed.hasPrefix("download:") || trimmed.contains("%") {
                        let now = CFAbsoluteTimeGetCurrent()
                        guard now - lastProgressUpdate >= progressThrottle else { continue }
                        lastProgressUpdate = now
                        if let pct = self.parsePercent(from: trimmed) {
                            let msg = trimmed.replacingOccurrences(of: "download:", with: "").trimmingCharacters(in: .whitespaces)
                            progress(pct / 100.0, "Downloading: \(msg)")
                        }
                    }
                    
                    // Detect merged/downloaded file path
                    if trimmed.hasPrefix("[Merger]") || trimmed.hasPrefix("[download]") || trimmed.hasPrefix("[ExtractAudio]") {
                        if let path = self.extractPath(from: trimmed) {
                            lastFilePath = path
                        }
                    }
                    // Capture bare filepath from --print after_move:filepath
                    else if !trimmed.hasPrefix("download:") && !trimmed.contains("%") && trimmed.hasPrefix("/") {
                        lastFilePath = trimmed
                    }
                }
            }
            
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
                
                for subline in line.components(separatedBy: .newlines) where !subline.isEmpty {
                    let trimmed = subline.trimmingCharacters(in: .whitespaces)
                    if trimmed.contains("[download]") && trimmed.contains("%") {
                        let now = CFAbsoluteTimeGetCurrent()
                        guard now - lastProgressUpdate >= progressThrottle else { continue }
                        lastProgressUpdate = now
                        if let pct = self.parsePercent(from: trimmed) {
                            progress(pct / 100.0, "Downloading: \(String(format: "%.1f%%", pct))")
                        }
                    }
                    // Capture file paths from stderr (yt-dlp writes [ExtractAudio], [Merger], [download] here)
                    if trimmed.hasPrefix("[Merger]") || trimmed.hasPrefix("[ExtractAudio]") || trimmed.hasPrefix("[download]") {
                        if let path = self.extractPath(from: trimmed) {
                            lastFilePath = path
                        }
                    }
                }
            }
            
            process.terminationHandler = { [weak self] proc in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                Task { await self?.removeProcess(proc) }
                
                if proc.terminationStatus == 0 {
                    progress(1.0, "Download complete")
                    continuation.resume(returning: lastFilePath)
                } else {
                    let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: NSError(
                        domain: "DownloadManager",
                        code: Int(proc.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: errStr.prefix(500).description]
                    ))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private static let percentRegex = try! NSRegularExpression(pattern: #"(\d+\.?\d*)%"#)
    
    private nonisolated func parsePercent(from string: String) -> Double? {
        // Match patterns like "45.2%" or "100%"
        guard let match = Self.percentRegex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: 1), in: string) else {
            return nil
        }
        return Double(string[range])
    }
    
    private nonisolated func extractPath(from string: String) -> String? {
        // Look for quoted paths or paths after "Merging formats into"
        if let range = string.range(of: "\"") {
            let after = string[range.upperBound...]
            if let endRange = after.range(of: "\"") {
                return String(after[..<endRange.lowerBound])
            }
        }
        
        // Look for "Destination:" pattern
        if let range = string.range(of: "Destination: ") {
            return String(string[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
}
