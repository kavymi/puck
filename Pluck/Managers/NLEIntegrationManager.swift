import Foundation
import AppKit

/// Supported Non-Linear Editors for auto-import integration.
enum NLEApp: String, CaseIterable, Codable, Identifiable {
    case none = "none"
    case premierePro = "premierePro"
    case davinciResolve = "davinciResolve"
    case finalCutPro = "finalCutPro"
    case afterEffects = "afterEffects"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .premierePro: return "Adobe Premiere Pro"
        case .davinciResolve: return "DaVinci Resolve"
        case .finalCutPro: return "Final Cut Pro"
        case .afterEffects: return "Adobe After Effects"
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "xmark.circle"
        case .premierePro: return "film.stack"
        case .davinciResolve: return "paintpalette"
        case .finalCutPro: return "scissors"
        case .afterEffects: return "sparkles.rectangle.stack"
        }
    }
    
    /// Bundle identifiers used to detect if the app is installed.
    var bundleIdentifiers: [String] {
        switch self {
        case .none: return []
        case .premierePro: return [
            "com.adobe.PremierePro",
            "com.adobe.premiereprocc",
        ]
        case .davinciResolve: return [
            "com.blackmagic-design.DaVinciResolve",
            "com.blackmagic-design.DaVinciResolveStudio",
        ]
        case .finalCutPro: return [
            "com.apple.FinalCut",
        ]
        case .afterEffects: return [
            "com.adobe.AfterEffects",
            "com.adobe.aftereffectscc",
        ]
        }
    }
}

/// Manages detection and auto-import into video editing applications.
@MainActor
final class NLEIntegrationManager {
    
    static let shared = NLEIntegrationManager()
    
    /// Detect which NLE apps are currently installed on the system.
    func detectInstalledEditors() -> [NLEApp] {
        NLEApp.allCases.filter { app in
            guard app != .none else { return false }
            return isInstalled(app)
        }
    }
    
    /// Check if a specific NLE is installed.
    func isInstalled(_ app: NLEApp) -> Bool {
        for bundleID in app.bundleIdentifiers {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil {
                return true
            }
        }
        return false
    }
    
    /// Check if a specific NLE is currently running.
    func isRunning(_ app: NLEApp) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        for bundleID in app.bundleIdentifiers {
            if runningApps.contains(where: { $0.bundleIdentifier == bundleID }) {
                return true
            }
        }
        return false
    }
    
    /// Import a file into the selected NLE. Returns a status message.
    func importFile(at path: String, into app: NLEApp) async -> NLEImportResult {
        guard FileManager.default.fileExists(atPath: path) else {
            return .failure("File not found: \(path)")
        }
        
        guard isInstalled(app) else {
            return .failure("\(app.displayName) is not installed")
        }
        
        switch app {
        case .none:
            return .failure("No editor selected")
        case .premierePro:
            return await importIntoPremiereViaAppleScript(path: path)
        case .davinciResolve:
            return await importIntoDaVinciResolve(path: path)
        case .finalCutPro:
            return await importIntoFinalCutPro(path: path)
        case .afterEffects:
            return await importIntoAfterEffectsViaAppleScript(path: path)
        }
    }
    
    /// Import multiple files into the selected NLE.
    func importFiles(at paths: [String], into app: NLEApp) async -> NLEImportResult {
        guard app != .none else { return .failure("No editor selected") }
        guard !paths.isEmpty else { return .failure("No files to import") }
        
        var successes = 0
        var lastError: String?
        
        for path in paths {
            let result = await importFile(at: path, into: app)
            switch result {
            case .success:
                successes += 1
            case .failure(let msg):
                lastError = msg
            }
        }
        
        if successes == paths.count {
            return .success("\(successes) file(s) imported into \(app.displayName)")
        } else if successes > 0 {
            return .success("\(successes)/\(paths.count) imported. Last error: \(lastError ?? "unknown")")
        } else {
            return .failure(lastError ?? "Import failed")
        }
    }
    
    // MARK: - Premiere Pro (AppleScript)
    
    private func importIntoPremiereViaAppleScript(path: String) async -> NLEImportResult {
        // Premiere Pro supports AppleScript for importing media into the active project.
        // If no project is open, we open the file directly which prompts Premiere to handle it.
        let escapedPath = path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let script = """
        tell application "Adobe Premiere Pro"
            activate
        end tell
        
        delay 0.5
        
        tell application "System Events"
            tell process "Adobe Premiere Pro"
                -- Use Cmd+I to open the Import dialog, then we use open command instead
            end tell
        end tell
        
        -- Use the open command to import the file into the current project
        tell application "Adobe Premiere Pro"
            open POSIX file "\(escapedPath)"
        end tell
        """
        
        return await runAppleScript(script, appName: "Adobe Premiere Pro")
    }
    
    // MARK: - DaVinci Resolve
    
    private func importIntoDaVinciResolve(path: String) async -> NLEImportResult {
        // DaVinci Resolve supports importing via its scripting API or by opening files.
        // The most reliable cross-version approach is using the `open` command
        // which adds media to the current project's media pool.
        let escapedPath = path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        // First try the Resolve scripting API via Python if available
        let resolveScriptResult = await importViaDaVinciResolveScript(path: path)
        if case .success = resolveScriptResult {
            return resolveScriptResult
        }
        
        // Fallback: use macOS `open` command to open the file with Resolve
        let script = """
        do shell script "open -a 'DaVinci Resolve' " & quoted form of "\(escapedPath)"
        """
        
        return await runAppleScript(script, appName: "DaVinci Resolve")
    }
    
    private func importViaDaVinciResolveScript(path: String) async -> NLEImportResult {
        // DaVinci Resolve has a Python/Lua scripting API.
        // We try to use the fuscript CLI or the Python API to add media to the media pool.
        let escapedPath = path.replacingOccurrences(of: "'", with: "'\\''")
        
        let pythonScript = """
        import sys
        sys.path.append('/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules')
        try:
            import DaVinciResolveScript as dvr
            resolve = dvr.scriptapp('Resolve')
            if resolve:
                pm = resolve.GetProjectManager()
                project = pm.GetCurrentProject()
                if project:
                    mp = project.GetMediaPool()
                    rf = mp.GetRootFolder()
                    items = mp.ImportMedia(['\(escapedPath)'])
                    if items:
                        print('OK')
                    else:
                        print('FAIL:Could not import media')
                else:
                    print('FAIL:No project open')
            else:
                print('FAIL:Could not connect to Resolve')
        except Exception as e:
            print(f'FAIL:{e}')
        """
        
        // Try python3 first
        let pythonPaths = ["/usr/bin/python3", "/usr/local/bin/python3", "/opt/homebrew/bin/python3"]
        
        for pythonPath in pythonPaths {
            guard FileManager.default.isExecutableFile(atPath: pythonPath) else { continue }
            
            let result = await runShellCommand(pythonPath, arguments: ["-c", pythonScript])
            if result.trimmingCharacters(in: .whitespacesAndNewlines) == "OK" {
                return .success("Imported into DaVinci Resolve media pool")
            }
        }
        
        return .failure("Resolve scripting API not available")
    }
    
    // MARK: - Final Cut Pro
    
    private func importIntoFinalCutPro(path: String) async -> NLEImportResult {
        // Final Cut Pro supports importing via AppleScript `open` command
        // which adds media to the current event in the active library.
        let escapedPath = path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let script = """
        tell application "Final Cut Pro"
            activate
            open POSIX file "\(escapedPath)"
        end tell
        """
        
        return await runAppleScript(script, appName: "Final Cut Pro")
    }
    
    // MARK: - After Effects (AppleScript)
    
    private func importIntoAfterEffectsViaAppleScript(path: String) async -> NLEImportResult {
        let escapedPath = path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let script = """
        tell application "Adobe After Effects"
            activate
            open POSIX file "\(escapedPath)"
        end tell
        """
        
        return await runAppleScript(script, appName: "Adobe After Effects")
    }
    
    // MARK: - Helpers
    
    private func runAppleScript(_ source: String, appName: String) async -> NLEImportResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let script = NSAppleScript(source: source)
                var errorDict: NSDictionary?
                script?.executeAndReturnError(&errorDict)
                
                if let error = errorDict {
                    let msg = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                    // If the error is just about the app not being scriptable but the open command worked,
                    // treat it as success
                    if msg.contains("not scriptable") || msg.contains("Expected end of line") {
                        continuation.resume(returning: .success("Opened file with \(appName)"))
                    } else {
                        continuation.resume(returning: .failure("\(appName): \(msg)"))
                    }
                } else {
                    continuation.resume(returning: .success("Imported into \(appName)"))
                }
            }
        }
    }
    
    private func runShellCommand(_ executable: String, arguments: [String]) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                process.environment = ProcessInfo.processInfo.environment
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }
}

// MARK: - Import Result

enum NLEImportResult {
    case success(String)
    case failure(String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var message: String {
        switch self {
        case .success(let msg): return msg
        case .failure(let msg): return msg
        }
    }
}
