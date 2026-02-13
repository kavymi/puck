import Foundation

/// Converts downloaded videos to ProRes 4444 .mov using ffmpeg with progress tracking.
actor ConversionManager {
    
    private var activeProcesses: Set<Process> = []
    private var isCancelled = false
    
    // MARK: - Public API
    
    /// Convert a video file to the configured format with progress reporting.
    func convert(
        inputPath: String,
        outputDir: URL,
        settings: ConversionSettings,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> String {
        isCancelled = false
        let ffmpeg = try BinaryManager.ffmpegURL()
        
        let inputURL = URL(fileURLWithPath: inputPath)
        
        let outputExtension: String
        switch settings.downloadMode {
        case .audioOnly:
            outputExtension = settings.audioFormat.rawValue
        case .both:
            outputExtension = settings.format.rawValue
        }
        
        let outputFilename = inputURL.deletingPathExtension().lastPathComponent + ".\(outputExtension)"
        let outputPath = outputDir.appendingPathComponent(outputFilename).path
        
        // Get duration first for progress calculation
        let duration = await getDuration(of: inputPath)
        
        var args = ["-y", "-i", inputPath]
        
        switch settings.downloadMode {
        case .audioOnly:
            // Audio-only: no video stream
            args.append(contentsOf: ["-vn"])
            switch settings.audioFormat {
            case .wav:
                // WAV uses PCM codec with configurable bit depth and sample rate
                args.append(contentsOf: [
                    "-c:a", settings.audioBitDepth.ffmpegFormat,
                    "-ar", String(settings.audioSampleRate.rawValue),
                ])
            case .flac:
                // FLAC supports sample rate; bit depth is set via sample_fmt
                let sampleFmt: String
                switch settings.audioBitDepth {
                case .bit16: sampleFmt = "s16"
                case .bit24: sampleFmt = "s32"
                case .bit32: sampleFmt = "s32"
                }
                args.append(contentsOf: [
                    "-c:a", "flac",
                    "-ar", String(settings.audioSampleRate.rawValue),
                    "-sample_fmt", sampleFmt,
                ])
            case .mp3:
                args.append(contentsOf: [
                    "-c:a", "libmp3lame",
                    "-b:a", "320k",
                    "-ar", String(settings.audioSampleRate.rawValue),
                ])
            case .m4a:
                args.append(contentsOf: [
                    "-c:a", "aac",
                    "-b:a", "256k",
                    "-ar", String(settings.audioSampleRate.rawValue),
                ])
            case .opus:
                args.append(contentsOf: [
                    "-c:a", "libopus",
                    "-b:a", "192k",
                    "-ar", "48000",
                ])
            case .ogg:
                args.append(contentsOf: [
                    "-c:a", "libvorbis",
                    "-q:a", "8",
                    "-ar", String(settings.audioSampleRate.rawValue),
                ])
            }
            
        case .both:
            // Video codec settings
            args.append(contentsOf: [
                "-c:v", "prores_ks",
                "-profile:v", settings.codec.ffmpegProfile,
                "-pix_fmt", "yuv422p10le",
            ])
            // Audio settings
            args.append(contentsOf: [
                "-c:a", settings.audioBitDepth.ffmpegFormat,
                "-ar", String(settings.audioSampleRate.rawValue),
            ])
        }
        
        // Preserve original properties
        args.append(contentsOf: [
            "-map", "0",
            "-progress", "pipe:1",
        ])
        
        args.append(outputPath)
        
        try await runConversion(
            executable: ffmpeg,
            arguments: args,
            totalDuration: duration,
            progress: progress
        )
        
        return outputPath
    }
    
    func cancel() {
        isCancelled = true
        for process in activeProcesses {
            process.terminate()
        }
        activeProcesses.removeAll()
    }
    
    // MARK: - Settings
    
    struct ConversionSettings: Sendable {
        let format: VideoFormat
        let codec: VideoCodec
        let audioSampleRate: AudioSampleRate
        let audioBitDepth: AudioBitDepth
        let downloadMode: DownloadMode
        let audioFormat: AudioFormat
        
        static func from(_ settings: AppSettings) -> ConversionSettings {
            ConversionSettings(
                format: settings.videoFormat,
                codec: settings.videoCodec,
                audioSampleRate: settings.audioSampleRate,
                audioBitDepth: settings.audioBitDepth,
                downloadMode: settings.downloadMode,
                audioFormat: settings.audioFormat
            )
        }
    }
    
    // MARK: - Private
    
    private func getDuration(of filePath: String) async -> Double {
        guard let ffprobe = BinaryManager.ffprobeURL() else { return 0 }
        
        // Run on a detached thread to avoid blocking the actor's cooperative executor
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                
                process.executableURL = ffprobe
                process.arguments = [
                    "-v", "quiet",
                    "-print_format", "json",
                    "-show_format",
                    filePath
                ]
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let format = json["format"] as? [String: Any],
                       let durationStr = format["duration"] as? String,
                       let duration = Double(durationStr) {
                        continuation.resume(returning: duration)
                        return
                    }
                } catch {}
                
                continuation.resume(returning: 0)
            }
        }
    }
    
    private func runConversion(
        executable: URL,
        arguments: [String],
        totalDuration: Double,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.environment = ProcessInfo.processInfo.environment
        
        activeProcesses.insert(process)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var buffer = ""
            var lastProgressUpdate = CFAbsoluteTimeGetCurrent()
            let progressThrottle: CFAbsoluteTime = 0.15
            
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                
                buffer += text
                
                // Parse ffmpeg progress output (key=value lines)
                while let newlineRange = buffer.range(of: "\n") {
                    let line = String(buffer[..<newlineRange.lowerBound])
                    buffer = String(buffer[newlineRange.upperBound...])
                    
                    if line.hasPrefix("out_time_us=") || line.hasPrefix("out_time_ms=") {
                        let now = CFAbsoluteTimeGetCurrent()
                        guard now - lastProgressUpdate >= progressThrottle else { continue }
                        lastProgressUpdate = now
                        let valueStr = line.components(separatedBy: "=").last ?? "0"
                        if let microseconds = Double(valueStr), totalDuration > 0 {
                            let currentSeconds = microseconds / 1_000_000
                            let pct = min(currentSeconds / totalDuration, 1.0)
                            let elapsed = Self.formatTime(currentSeconds)
                            let total = Self.formatTime(totalDuration)
                            progress(pct, "Converting: \(elapsed) / \(total)")
                        }
                    } else if line.hasPrefix("out_time=") {
                        let now = CFAbsoluteTimeGetCurrent()
                        guard now - lastProgressUpdate >= progressThrottle else { continue }
                        lastProgressUpdate = now
                        let timeStr = line.components(separatedBy: "=").last ?? "00:00:00"
                        if let seconds = Self.parseTimeString(timeStr), totalDuration > 0 {
                            let pct = min(seconds / totalDuration, 1.0)
                            let elapsed = Self.formatTime(seconds)
                            let total = Self.formatTime(totalDuration)
                            progress(pct, "Converting: \(elapsed) / \(total)")
                        }
                    } else if line == "progress=end" {
                        progress(1.0, "Conversion complete")
                    }
                }
            }
            
            process.terminationHandler = { proc in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                
                Task { await self.removeProcess(proc) }
                
                if proc.terminationStatus == 0 {
                    progress(1.0, "Conversion complete")
                    continuation.resume()
                } else {
                    let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: NSError(
                        domain: "ConversionManager",
                        code: Int(proc.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: "ffmpeg error: \(errStr.suffix(500))"]
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
    
    // MARK: - Helpers
    
    private static func parseTimeString(_ timeStr: String) -> Double? {
        // Parse "HH:MM:SS.microseconds" format
        let cleaned = timeStr.trimmingCharacters(in: .whitespaces)
        let parts = cleaned.components(separatedBy: ":")
        guard parts.count == 3 else { return nil }
        
        guard let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2]) else { return nil }
        
        return hours * 3600 + minutes * 60 + seconds
    }
    
    private static func formatTime(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
