import SwiftUI

struct DownloadItemRow: View {
    let item: DownloadItem
    var onReveal: () -> Void
    var onRetry: () -> Void
    var onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.system(.body, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    if let idx = item.playlistIndex, let total = item.playlistTotal {
                        Text("[\(idx)/\(total)]")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Progress bars
                if item.status == .downloading || item.status == .converting {
                    progressSection
                }
                
                HStack(spacing: 6) {
                    Text(item.statusMessage)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                    
                    if let error = item.error {
                        Text("— \(error)")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            actionButtons
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Status Icon
    
    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .queued:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
                .frame(width: 24)
        case .downloading:
            ProgressView()
                .controlSize(.small)
                .frame(width: 24)
        case .converting:
            Image(systemName: "wand.and.stars")
                .foregroundStyle(Color(red: 0.6, green: 0.5, blue: 1.0))
                .symbolEffect(.pulse)
                .frame(width: 24)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(width: 24)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .frame(width: 24)
        case .cancelled:
            Image(systemName: "xmark.circle")
                .foregroundStyle(.secondary)
                .frame(width: 24)
        }
    }
    
    // MARK: - Progress
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            if item.status == .downloading {
                HStack(spacing: 6) {
                    ProgressView(value: item.downloadProgress)
                        .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                    Text("\(Int(item.downloadProgress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 32, alignment: .trailing)
                }
            }
            
            if item.status == .converting {
                HStack(spacing: 6) {
                    ProgressView(value: item.conversionProgress)
                        .tint(Color(red: 0.6, green: 0.5, blue: 1.0))
                    Text("\(Int(item.conversionProgress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private var actionButtons: some View {
        HStack(spacing: 4) {
            if item.status == .completed {
                Button {
                    onReveal()
                } label: {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
            }
            
            if item.status == .failed || item.status == .cancelled {
                Button {
                    onRetry()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Retry")
            }
            
            if item.status != .downloading && item.status != .converting {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove")
            }
        }
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch item.status {
        case .queued: return .secondary
        case .downloading: return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .converting: return Color(red: 0.6, green: 0.5, blue: 1.0)
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .secondary
        }
    }
}
