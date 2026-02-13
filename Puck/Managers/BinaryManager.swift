import Foundation

/// Locates yt-dlp and ffmpeg binaries — checks the app bundle first, then common system paths.
struct BinaryManager {
    
    enum BinaryError: LocalizedError {
        case notFound(String)
        
        var errorDescription: String? {
            switch self {
            case .notFound(let name):
                return "\(name) not found. Please install it via Homebrew: brew install \(name)"
            }
        }
    }
    
    // MARK: - Cache
    
    private static let cacheLock = NSLock()
    private static var cache: [String: URL?] = [:]
    
    /// Clear cached lookups (e.g. after user installs a missing binary).
    static func invalidateCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cache.removeAll()
    }
    
    // MARK: - Public
    
    static func ytdlpURL() throws -> URL {
        if let url = locateCached("yt-dlp") { return url }
        throw BinaryError.notFound("yt-dlp")
    }
    
    static func ffmpegURL() throws -> URL {
        if let url = locateCached("ffmpeg") { return url }
        throw BinaryError.notFound("ffmpeg")
    }
    
    static func ffprobeURL() -> URL? {
        locateCached("ffprobe")
    }
    
    static var ytdlpAvailable: Bool { locateCached("yt-dlp") != nil }
    static var ffmpegAvailable: Bool { locateCached("ffmpeg") != nil }
    
    // MARK: - Private
    
    private static func locateCached(_ name: String) -> URL? {
        cacheLock.lock()
        if let cached = cache[name] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        let result = locate(name)
        cacheLock.lock()
        cache[name] = result
        cacheLock.unlock()
        return result
    }
    
    private static func locate(_ name: String) -> URL? {
        // 1. Check inside the app bundle's Resources/bin directory
        if let bundled = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "bin") {
            stripQuarantine(bundled)
            return bundled
        }
        
        // 2. Check inside the app bundle's MacOS directory
        if let bundleExec = Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent(name),
           FileManager.default.isExecutableFile(atPath: bundleExec.path) {
            return bundleExec
        }
        
        // 3. Common Homebrew / system paths
        let systemPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
        ]
        
        for path in systemPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        
        // 4. Fall back to `which`
        if let whichPath = shell("which \(name)") {
            let url = URL(fileURLWithPath: whichPath)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
        }
        
        return nil
    }
    
    private static func stripQuarantine(_ url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-dr", "com.apple.quarantine", url.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
    
    private static func shell(_ command: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
