import SwiftUI

struct DownloadItemRow: View {
    let item: DownloadItem
    var onReveal: () -> Void
    var onImport: () -> Void
    var onRetry: () -> Void
    var onRemove: () -> Void
    @State private var isHovered = false
    @State private var didComplete = false
    
    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.system(.body, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    if let idx = item.playlistIndex, let total = item.playlistTotal {
                        Text("\(idx)/\(total)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(PuckTheme.orb.opacity(0.4))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(PuckTheme.orb.opacity(0.06))
                            )
                    }
                }
                
                // Progress bars
                if item.status == .downloading || item.status == .converting {
                    progressSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                HStack(spacing: 6) {
                    Text(item.statusMessage)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                        .contentTransition(.numericText())
                    
                    if let error = item.error {
                        Text("— \(error)")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            actionButtons
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: PuckTheme.cardRadius)
                .fill(.ultraThinMaterial)
                .opacity(isHovered ? 0.7 : 0.4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PuckTheme.cardRadius)
                .stroke(
                    isHovered ? PuckTheme.orb.opacity(0.15) : PuckTheme.orb.opacity(0.05),
                    lineWidth: 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: PuckTheme.cardRadius))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.15), value: item.status)
        .onChange(of: item.status) { oldValue, newValue in
            if newValue == .completed {
                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                    didComplete = true
                }
            }
        }
    }
    
    // MARK: - Status Icon
    
    @ViewBuilder
    private var statusIcon: some View {
        Group {
            switch item.status {
            case .queued:
                Image(systemName: "moon")
                    .foregroundStyle(PuckTheme.orb.opacity(0.3))
            case .downloading:
                ZStack {
                    Circle()
                        .fill(PuckTheme.orb.opacity(0.06))
                        .frame(width: 24, height: 24)
                    ProgressView()
                        .controlSize(.small)
                        .tint(PuckTheme.orb)
                }
            case .converting:
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(PuckTheme.coil)
                    .shadow(color: PuckTheme.coil.opacity(0.3), radius: 4)
                    .symbolEffect(.pulse, options: .repeating)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(PuckTheme.orb)
                    .shadow(color: PuckTheme.orb.opacity(0.3), radius: 4)
                    .symbolEffect(.bounce, value: didComplete)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red.opacity(0.8))
                    .symbolEffect(.bounce, value: item.status == .failed)
            case .cancelled:
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .frame(width: 24)
        .contentTransition(.symbolEffect(.replace.downUp))
    }
    
    // MARK: - Progress
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            if item.status == .downloading {
                HStack(spacing: 6) {
                    ProgressView(value: item.downloadProgress)
                        .tint(PuckTheme.orb)
                        .animation(.easeOut(duration: 0.3), value: item.downloadProgress)
                    Text("\(Int(item.downloadProgress * 100))%")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(PuckTheme.orb.opacity(0.6))
                        .frame(width: 32, alignment: .trailing)
                        .contentTransition(.numericText())
                }
            }
            
            if item.status == .converting {
                HStack(spacing: 6) {
                    ProgressView(value: item.conversionProgress)
                        .tint(PuckTheme.coil)
                        .animation(.easeOut(duration: 0.3), value: item.conversionProgress)
                    Text("\(Int(item.conversionProgress * 100))%")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(PuckTheme.coil.opacity(0.6))
                        .frame(width: 32, alignment: .trailing)
                        .contentTransition(.numericText())
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private var actionButtons: some View {
        HStack(spacing: 6) {
            if item.status == .completed {
                Button {
                    onImport()
                } label: {
                    Image(systemName: "film.stack")
                        .font(.caption)
                        .foregroundStyle(PuckTheme.coil.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Import into editor")
                .transition(.scale.combined(with: .opacity))
                
                Button {
                    onReveal()
                } label: {
                    Image(systemName: "folder")
                        .font(.caption)
                        .foregroundStyle(PuckTheme.orb.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
                .transition(.scale.combined(with: .opacity))
            }
            
            if item.status == .failed || item.status == .cancelled {
                Button {
                    onRetry()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(PuckTheme.orb.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Retry")
                .transition(.scale.combined(with: .opacity))
            }
            
            if item.status != .downloading && item.status != .converting {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .help("Remove")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: item.status)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch item.status {
        case .queued: return PuckTheme.orb.opacity(0.3)
        case .downloading: return PuckTheme.orb
        case .converting: return PuckTheme.coil
        case .completed: return PuckTheme.orb
        case .failed: return .red.opacity(0.7)
        case .cancelled: return .secondary.opacity(0.5)
        }
    }
}
