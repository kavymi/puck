import Foundation
import SwiftUI

@Observable
@MainActor
final class DownloadViewModel {
    
    var items: [DownloadItem] = []
    var urlInput: String = ""
    var logMessages: [String] = []
    var isProcessing = false
    var ytdlpAvailable = false
    var ffmpegAvailable = false
    
    private let downloadManager = DownloadManager()
    private let conversionManager = ConversionManager()
    private let settings = AppSettings.shared
    
    init() {
        checkDependencies()
    }
    
    // MARK: - Dependency Check
    
    func checkDependencies() {
        BinaryManager.invalidateCache()
        ytdlpAvailable = BinaryManager.ytdlpAvailable
        ffmpegAvailable = BinaryManager.ffmpegAvailable
        
        if ytdlpAvailable {
            log("yt-dlp found")
        } else {
            log("WARNING: yt-dlp not found. Install via: brew install yt-dlp")
        }
        
        if ffmpegAvailable {
            log("ffmpeg found")
        } else {
            log("WARNING: ffmpeg not found. Install via: brew install ffmpeg")
            if settings.audioFormat == .wav && settings.downloadMode == .audioOnly {
                log("WARNING: WAV audio requires ffmpeg for conversion. Without it, audio settings (sample rate, bit depth) will not be applied.")
            }
        }
    }
    
    // MARK: - URL Handling
    
    func addURLs(from text: String) {
        let urls = parseURLs(from: text)
        guard !urls.isEmpty else {
            log("No valid URLs found.")
            return
        }
        
        for url in urls {
            let item = DownloadItem(url: url)
            items.append(item)
        }
        
        log("Added \(urls.count) URL(s) to queue.")
    }
    
    func handleDrop(of urls: [String]) {
        for url in urls {
            let item = DownloadItem(url: url)
            items.append(item)
        }
        log("Dropped \(urls.count) URL(s).")
    }
    
    // MARK: - Processing
    
    func startProcessing() {
        guard !isProcessing else { return }
        
        let pendingItems = items.filter { $0.status == .queued }
        guard !pendingItems.isEmpty else {
            log("No queued items to process.")
            return
        }
        
        isProcessing = true
        let maxConcurrent = settings.maxConcurrentDownloads
        log("Phase Shift initiated — \(pendingItems.count) targets, \(maxConcurrent) concurrent streams")
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                var running = 0
                
                for item in pendingItems {
                    guard isProcessing else { break }
                    
                    group.addTask { [weak self] in
                        guard let self else { return }
                        await self.processItem(item)
                    }
                    running += 1
                    
                    if running >= maxConcurrent {
                        await group.next()
                        running -= 1
                    }
                }
                
                await group.waitForAll()
            }
            isProcessing = false
            log("Dream Coil complete — all downloads finished.")
        }
    }
    
    func startSingleItem(_ item: DownloadItem) {
        guard item.status == .queued || item.status == .failed else { return }
        item.status = .queued
        item.error = nil
        
        Task {
            isProcessing = true
            await processItem(item)
            isProcessing = items.contains(where: { $0.status == .downloading || $0.status == .converting })
        }
    }
    
    func cancelAll() {
        isProcessing = false
        Task {
            await downloadManager.cancel()
            await conversionManager.cancel()
        }
        for item in items where item.status == .downloading || item.status == .converting {
            item.status = .cancelled
            item.statusMessage = "Cancelled"
        }
        log("Cancelled all downloads.")
    }
    
    func removeItem(_ item: DownloadItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func removeCompleted() {
        items.removeAll { $0.status == .completed }
    }
    
    func clearAll() {
        cancelAll()
        items.removeAll()
        logMessages.removeAll()
    }
    
    // MARK: - Private Processing
    
    private func processItem(_ item: DownloadItem) async {
        let urlType = item.urlType
        
        if urlType == .youtubePlaylist {
            await processPlaylist(item)
        } else {
            await processSingleVideo(item)
        }
    }
    
    private func processSingleVideo(_ item: DownloadItem) async {
        item.status = .downloading
        item.statusMessage = "Starting download..."
        log("Downloading: \(item.url)")
        
        do {
            let outputDir = settings.outputDirectory
            try settings.ensureOutputDirectoryExists()
            
            let downloadedPath = try await downloadManager.downloadAndGetPath(
                url: item.url,
                to: outputDir,
                mode: settings.downloadMode,
                audioFormat: settings.audioFormat
            ) { [weak item] progress, message in
                Task { @MainActor in
                    item?.downloadProgress = progress
                    item?.statusMessage = message
                }
            }
            
            guard isProcessing || item.status == .downloading else {
                item.status = .cancelled
                return
            }
            
            // Update title from filename
            let filename = URL(fileURLWithPath: downloadedPath).deletingPathExtension().lastPathComponent
            if item.title == item.url {
                item.title = filename
            }
            
            log("Downloaded: \(filename)")
            
            // Convert if enabled, or always for WAV audio-only (to apply sample rate / bit depth)
            let needsConversion = (settings.autoConvert || (settings.downloadMode == .audioOnly && settings.audioFormat == .wav)) && ffmpegAvailable
            if needsConversion {
                item.status = .converting
                item.statusMessage = "Starting conversion..."
                item.conversionProgress = 0
                
                let convSettings = ConversionManager.ConversionSettings.from(settings)
                
                let convertedPath = try await conversionManager.convert(
                    inputPath: downloadedPath,
                    outputDir: outputDir,
                    settings: convSettings
                ) { [weak item] progress, message in
                    Task { @MainActor in
                        item?.conversionProgress = progress
                        item?.statusMessage = message
                    }
                }
                
                item.outputPath = convertedPath
                
                // Remove original if not preserving
                if !settings.preserveOriginal && downloadedPath != convertedPath {
                    try? FileManager.default.removeItem(atPath: downloadedPath)
                }
                
                log("Converted: \(URL(fileURLWithPath: convertedPath).lastPathComponent)")
            } else {
                item.outputPath = downloadedPath
            }
            
            item.status = .completed
            item.statusMessage = "Complete"
            item.downloadProgress = 1.0
            item.conversionProgress = 1.0
            
        } catch {
            item.status = .failed
            item.error = error.localizedDescription
            item.statusMessage = "Failed"
            log("Error: \(error.localizedDescription)")
        }
    }
    
    private func processPlaylist(_ item: DownloadItem) async {
        item.status = .downloading
        item.statusMessage = "Fetching playlist info..."
        log("Fetching playlist: \(item.url)")
        
        do {
            let info = try await downloadManager.fetchInfo(url: item.url)
            
            guard info.isPlaylist else {
                // Not actually a playlist, treat as single video
                await processSingleVideo(item)
                return
            }
            
            item.title = info.playlistTitle ?? "Playlist"
            item.playlistName = info.playlistTitle
            let total = info.entries.count
            log("Playlist '\(item.title)' has \(total) videos")
            
            // Create playlist subfolder
            let playlistDir = settings.outputDirectory.appendingPathComponent(item.title)
            try FileManager.default.createDirectory(at: playlistDir, withIntermediateDirectories: true)
            
            // Add individual items
            var playlistItems: [DownloadItem] = []
            for entry in info.entries {
                let subItem = DownloadItem(url: entry.url, title: entry.title)
                subItem.playlistName = item.title
                subItem.playlistIndex = entry.index + 1
                subItem.playlistTotal = total
                playlistItems.append(subItem)
            }
            
            // Replace the playlist item with individual items
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items.remove(at: idx)
                items.insert(contentsOf: playlistItems, at: idx)
            }
            
            // Process playlist items concurrently
            let maxConcurrent = settings.maxConcurrentDownloads
            await withTaskGroup(of: Void.self) { group in
                var running = 0
                
                for subItem in playlistItems {
                    guard isProcessing else { break }
                    
                    group.addTask { [weak self] in
                        guard let self else { return }
                        await self.processPlaylistItem(subItem, in: playlistDir, total: total)
                    }
                    running += 1
                    
                    if running >= maxConcurrent {
                        await group.next()
                        running -= 1
                    }
                }
                
                await group.waitForAll()
            }
            
        } catch {
            item.status = .failed
            item.error = error.localizedDescription
            item.statusMessage = "Failed to fetch playlist"
            log("Playlist error: \(error.localizedDescription)")
        }
    }
    
    private func processPlaylistItem(_ subItem: DownloadItem, in playlistDir: URL, total: Int) async {
        subItem.status = .downloading
        subItem.statusMessage = "Starting download..."
        log("[\(subItem.playlistIndex ?? 0)/\(total)] \(subItem.title)")
        
        do {
            let downloadedPath = try await downloadManager.downloadAndGetPath(
                url: subItem.url,
                to: playlistDir,
                mode: settings.downloadMode,
                audioFormat: settings.audioFormat
            ) { [weak subItem] progress, message in
                Task { @MainActor in
                    subItem?.downloadProgress = progress
                    subItem?.statusMessage = message
                }
            }
            
            let filename = URL(fileURLWithPath: downloadedPath).deletingPathExtension().lastPathComponent
            if subItem.title == subItem.url {
                subItem.title = filename
            }
            
            // Convert if enabled, or always for WAV audio-only (to apply sample rate / bit depth)
            let needsConversion = (settings.autoConvert || (settings.downloadMode == .audioOnly && settings.audioFormat == .wav)) && ffmpegAvailable
            if needsConversion {
                subItem.status = .converting
                subItem.statusMessage = "Starting conversion..."
                subItem.conversionProgress = 0
                
                let convSettings = ConversionManager.ConversionSettings.from(settings)
                
                let convertedPath = try await conversionManager.convert(
                    inputPath: downloadedPath,
                    outputDir: playlistDir,
                    settings: convSettings
                ) { [weak subItem] progress, message in
                    Task { @MainActor in
                        subItem?.conversionProgress = progress
                        subItem?.statusMessage = message
                    }
                }
                
                subItem.outputPath = convertedPath
                
                if !settings.preserveOriginal && downloadedPath != convertedPath {
                    try? FileManager.default.removeItem(atPath: downloadedPath)
                }
            } else {
                subItem.outputPath = downloadedPath
            }
            
            subItem.status = .completed
            subItem.statusMessage = "Complete"
            subItem.downloadProgress = 1.0
            subItem.conversionProgress = 1.0
            
        } catch {
            subItem.status = .failed
            subItem.error = error.localizedDescription
            subItem.statusMessage = "Failed"
            log("Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helpers
    
    private func parseURLs(from text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("http://") || $0.hasPrefix("https://") }
    }
    
    func log(_ message: String) {
        let timestamp = Self.timeFormatter.string(from: Date())
        let formatted = "[\(timestamp)] \(message)"
        logMessages.append(formatted)
        print(formatted)
        // Cap log to 1000 entries to prevent unbounded memory growth
        if logMessages.count > 1000 {
            logMessages.removeFirst(logMessages.count - 1000)
        }
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    
    func openOutputFolder() {
        NSWorkspace.shared.open(settings.outputDirectory)
    }
    
    func revealInFinder(_ item: DownloadItem) {
        guard let path = item.outputPath else { return }
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}
