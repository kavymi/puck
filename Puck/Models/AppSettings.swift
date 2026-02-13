import Foundation
import SwiftUI

enum DownloadMode: String, CaseIterable, Codable {
    case audioOnly = "audioOnly"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .audioOnly: return "Audio Only"
        case .both: return "Video + Audio"
        }
    }
}

enum VideoFormat: String, CaseIterable, Codable {
    case mov = "mov"
    
    var displayName: String {
        switch self {
        case .mov: return "ProRes .mov"
        }
    }
}

enum VideoCodec: String, CaseIterable, Codable {
    case proresProxy = "prores_proxy"
    case proresLT = "prores_lt"
    case proresHQ = "prores_hq"
    
    var displayName: String {
        switch self {
        case .proresProxy: return "ProRes 422 Proxy"
        case .proresLT: return "ProRes 422 LT"
        case .proresHQ: return "ProRes 422 HQ"
        }
    }
    
    var ffmpegProfile: String {
        switch self {
        case .proresProxy: return "0"
        case .proresLT: return "1"
        case .proresHQ: return "3"
        }
    }
}

enum AudioFormat: String, CaseIterable, Codable {
    case mp3 = "mp3"
    case m4a = "m4a"
    case flac = "flac"
    case wav = "wav"
    case opus = "opus"
    case ogg = "ogg"
    
    var displayName: String {
        switch self {
        case .mp3: return "MP3"
        case .m4a: return "M4A (AAC)"
        case .flac: return "FLAC"
        case .wav: return "WAV"
        case .opus: return "Opus"
        case .ogg: return "OGG Vorbis"
        }
    }
}

enum AudioSampleRate: Int, CaseIterable, Codable {
    case rate44100 = 44100
    case rate48000 = 48000
    case rate96000 = 96000
    
    var displayName: String { "\(rawValue / 1000)kHz" }
}

enum AudioBitDepth: Int, CaseIterable, Codable {
    case bit16 = 16
    case bit24 = 24
    case bit32 = 32
    
    var displayName: String { "\(rawValue)-bit" }
    
    var ffmpegFormat: String {
        switch self {
        case .bit16: return "pcm_s16le"
        case .bit24: return "pcm_s24le"
        case .bit32: return "pcm_s32le"
        }
    }
}

@Observable
final class AppSettings: @unchecked Sendable {
    static let shared = AppSettings()
    
    var outputDirectory: URL {
        didSet { save() }
    }
    var videoFormat: VideoFormat = .mov {
        didSet { save() }
    }
    var videoCodec: VideoCodec = .proresHQ {
        didSet { save() }
    }
    var audioSampleRate: AudioSampleRate = .rate48000 {
        didSet { save() }
    }
    var audioBitDepth: AudioBitDepth = .bit24 {
        didSet { save() }
    }
    var downloadMode: DownloadMode = .both {
        didSet { save() }
    }
    var audioFormat: AudioFormat = .mp3 {
        didSet { save() }
    }
    var autoConvert: Bool = true {
        didSet { save() }
    }
    var preserveOriginal: Bool = false {
        didSet { save() }
    }
    var maxConcurrentDownloads: Int = 4 {
        didSet { save() }
    }
    
    private let defaults = UserDefaults.standard
    
    private init() {
        let defaultDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Puck")
        
        if let savedPath = defaults.string(forKey: "outputDirectory") {
            outputDirectory = URL(fileURLWithPath: savedPath)
        } else {
            outputDirectory = defaultDir
        }
        
        if let raw = defaults.string(forKey: "videoFormat"), let val = VideoFormat(rawValue: raw) {
            videoFormat = val
        }
        if let raw = defaults.string(forKey: "videoCodec"), let val = VideoCodec(rawValue: raw) {
            videoCodec = val
        }
        if let raw = defaults.integer(forKey: "audioSampleRate") as Int?, raw != 0,
           let val = AudioSampleRate(rawValue: raw) {
            audioSampleRate = val
        }
        if let raw = defaults.integer(forKey: "audioBitDepth") as Int?, raw != 0,
           let val = AudioBitDepth(rawValue: raw) {
            audioBitDepth = val
        }
        if let raw = defaults.string(forKey: "downloadMode"), let val = DownloadMode(rawValue: raw) {
            downloadMode = val
        }
        if let raw = defaults.string(forKey: "audioFormat"), let val = AudioFormat(rawValue: raw) {
            audioFormat = val
        }
        autoConvert = defaults.object(forKey: "autoConvert") as? Bool ?? true
        preserveOriginal = defaults.object(forKey: "preserveOriginal") as? Bool ?? false
        if let saved = defaults.integer(forKey: "maxConcurrentDownloads") as Int?, saved > 0 {
            maxConcurrentDownloads = saved
        }
    }
    
    private func save() {
        defaults.set(outputDirectory.path, forKey: "outputDirectory")
        defaults.set(videoFormat.rawValue, forKey: "videoFormat")
        defaults.set(videoCodec.rawValue, forKey: "videoCodec")
        defaults.set(audioSampleRate.rawValue, forKey: "audioSampleRate")
        defaults.set(audioBitDepth.rawValue, forKey: "audioBitDepth")
        defaults.set(downloadMode.rawValue, forKey: "downloadMode")
        defaults.set(audioFormat.rawValue, forKey: "audioFormat")
        defaults.set(autoConvert, forKey: "autoConvert")
        defaults.set(preserveOriginal, forKey: "preserveOriginal")
        defaults.set(maxConcurrentDownloads, forKey: "maxConcurrentDownloads")
    }
    
    func ensureOutputDirectoryExists() throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }
}
