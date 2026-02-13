import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var viewModel = DownloadViewModel()
    @State private var showSettings = false
    @State private var isDropTargeted = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // URL Input
            urlInputSection
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            // Action Buttons
            actionButtons
                .padding(.horizontal, 20)
                .padding(.top, 12)
            
            Divider()
                .padding(.top, 12)
            
            // Download Queue
            if !viewModel.items.isEmpty {
                downloadQueueSection
            } else {
                emptyStateView
            }
            
            Divider()
            
            // Log
            logSection
        }
        .frame(minWidth: 700, minHeight: 600)
        .background(Color(.windowBackgroundColor))
        .onDrop(of: [.plainText, .url], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDropTargeted {
                dropOverlay
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.checkDependencies()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh dependency status")
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Puck")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.6, green: 0.5, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("v2")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(.secondary.opacity(0.15)))
                }
                
                Text(puckSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            dependencyBadges
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var dependencyBadges: some View {
        HStack(spacing: 8) {
            StatusBadge(
                label: "yt-dlp",
                available: viewModel.ytdlpAvailable
            )
            StatusBadge(
                label: "ffmpeg",
                available: viewModel.ffmpegAvailable
            )
        }
    }
    
    // MARK: - Puck Flavor
    
    private static let puckSubtitles = [
        "I find myself surprisingly comfortable in this world.",
        "Shall we have a game, then?",
        "The Dreaming Tree watches over your downloads.",
        "Phase Shift your media across the planes.",
        "Illusory Orb inbound... fetching your videos.",
        "Waning Rift tears through bandwidth limits.",
        "Dream Coil binds your playlist to this realm.",
    ]
    
    private var puckSubtitle: String {
        Self.puckSubtitles[Int.random(in: 0..<Self.puckSubtitles.count)]
    }
    
    // MARK: - URL Input
    
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Summon URLs")
                .font(.headline)
            
            TextEditor(text: $viewModel.urlInput)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
                .frame(minHeight: 80, maxHeight: 120)
                .overlay(alignment: .topLeading) {
                    if viewModel.urlInput.isEmpty {
                        Text("Paste URLs here, or drag & drop a link into the Dreaming Pool...")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.addURLs(from: viewModel.urlInput)
                viewModel.urlInput = ""
                viewModel.startProcessing()
            } label: {
                Label("Download", systemImage: "arrow.down.circle.fill")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .disabled(viewModel.urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !viewModel.ytdlpAvailable)
            .keyboardShortcut(.return, modifiers: .command)
            
            Button {
                viewModel.addURLs(from: viewModel.urlInput)
                viewModel.urlInput = ""
            } label: {
                Label("Add to Queue", systemImage: "plus.circle")
            }
            .disabled(viewModel.urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            if viewModel.isProcessing {
                Button(role: .destructive) {
                    viewModel.cancelAll()
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
            } else if !viewModel.items.filter({ $0.status == .queued }).isEmpty {
                Button {
                    viewModel.startProcessing()
                } label: {
                    Label("Start Queue", systemImage: "play.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            
            Spacer()
            
            Button {
                viewModel.openOutputFolder()
            } label: {
                Label("Open Folder", systemImage: "folder")
            }
            
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
    }
    
    // MARK: - Download Queue
    
    private var downloadQueueSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Queue")
                    .font(.headline)
                
                Text("(\(viewModel.items.count))")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if viewModel.items.contains(where: { $0.status == .completed }) {
                    Button("Clear Completed") {
                        viewModel.removeCompleted()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                
                Button("Clear All") {
                    viewModel.clearAll()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(viewModel.items) { item in
                        DownloadItemRow(item: item) {
                            viewModel.revealInFinder(item)
                        } onRetry: {
                            viewModel.startSingleItem(item)
                        } onRemove: {
                            viewModel.removeItem(item)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.6, green: 0.5, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text("The Dreaming Pool is empty")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Paste a URL above or drag & drop to begin the Phase Shift")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Log
    
    private var logSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Log")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Clear") {
                    viewModel.logMessages.removeAll()
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(viewModel.logMessages.enumerated()), id: \.offset) { idx, msg in
                            Text(msg)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .id(idx)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 80)
                .onChange(of: viewModel.logMessages.count) { _, _ in
                    if let last = viewModel.logMessages.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Drop Overlay
    
    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.6, green: 0.5, blue: 1.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("Release into the Dream Coil")
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.tint, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
            }
            .padding(8)
    }
    
    // MARK: - Drop Handling
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: String.self) {
                _ = provider.loadObject(ofClass: String.self) { string, _ in
                    if let string = string {
                        Task { @MainActor in
                            viewModel.addURLs(from: string)
                        }
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let label: String
    let available: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(available ? .green : .red)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(available ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

#Preview {
    ContentView()
}
