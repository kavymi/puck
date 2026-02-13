import Foundation

enum DownloadStatus: String, Codable {
    case queued
    case downloading
    case converting
    case completed
    case failed
    case cancelled
}

enum URLType: String {
    case youtubeVideo
    case youtubePlaylist
    case vimeo
    case unknown
    
    static func classify(_ url: String) -> URLType {
        if url.contains("youtube.com/playlist") || url.contains("list=") {
            return .youtubePlaylist
        } else if url.contains("youtube.com") || url.contains("youtu.be") {
            return .youtubeVideo
        } else if url.contains("vimeo.com") {
            return .vimeo
        }
        return .unknown
    }
}

@Observable
final class DownloadItem: Identifiable {
    let id = UUID()
    let url: String
    let urlType: URLType
    var title: String
    var status: DownloadStatus = .queued
    var downloadProgress: Double = 0
    var conversionProgress: Double = 0
    var statusMessage: String = "Queued"
    var outputPath: String?
    var playlistName: String?
    var playlistIndex: Int?
    var playlistTotal: Int?
    var error: String?
    
    var isPlaylistItem: Bool { playlistName != nil }
    
    var overallProgress: Double {
        switch status {
        case .queued: return 0
        case .downloading: return downloadProgress * 0.5
        case .converting: return 0.5 + conversionProgress * 0.5
        case .completed: return 1.0
        case .failed, .cancelled: return 0
        }
    }
    
    init(url: String, title: String? = nil) {
        self.url = url
        self.urlType = URLType.classify(url)
        self.title = title ?? url
    }
}
