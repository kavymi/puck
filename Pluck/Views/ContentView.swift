import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var viewModel = DownloadViewModel()
    @State private var showSettings = false
    @State private var isDropTargeted = false
    @State private var emptyStatePulse = false
    @State private var headerGlow = false
    @State private var puckSubtitleText = Self.puckSubtitles.randomElement()!
    
    var body: some View {
        ZStack {
            // Deep background
            Color(.windowBackgroundColor)
                .ignoresSafeArea()
            
            // Ambient glow orbs
            ambientBackground
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Ethereal divider
                puckDivider
                
                // URL Input
                urlInputSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Action Buttons
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                
                // Inline Settings
                if showSettings {
                    puckDivider
                        .padding(.top, 12)
                    
                    ScrollView {
                        SettingsView()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .frame(maxHeight: 300)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                puckDivider
                    .padding(.top, showSettings ? 0 : 12)
                
                // Download Queue
                if !viewModel.items.isEmpty {
                    downloadQueueSection
                        .transition(.opacity)
                } else {
                    emptyStateView
                        .transition(.opacity)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .onDrop(of: [.plainText, .url], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDropTargeted {
                dropOverlay
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.15), value: showSettings)
        .animation(.easeInOut(duration: 0.3), value: viewModel.items.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.currentError {
                Text(error)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.checkDependencies()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(PuckTheme.orb.opacity(0.7))
                }
                .help("Refresh dependency status")
            }
        }
    }
    
    // MARK: - Ambient Background
    
    private var ambientBackground: some View {
        ZStack {
            // Top-left orb glow
            Circle()
                .fill(PuckTheme.orb.opacity(0.04))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -150, y: -200)
                .scaleEffect(headerGlow ? 1.1 : 0.9)
            
            // Bottom-right coil glow
            Circle()
                .fill(PuckTheme.coil.opacity(0.03))
                .frame(width: 350, height: 350)
                .blur(radius: 100)
                .offset(x: 200, y: 200)
                .scaleEffect(headerGlow ? 0.9 : 1.1)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                headerGlow = true
            }
        }
    }
    
    // MARK: - Puck Divider
    
    private var puckDivider: some View {
        Rectangle()
            .fill(PuckTheme.primaryGradient)
            .frame(height: 0.5)
            .opacity(0.2)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    // Puck orb icon
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundStyle(PuckTheme.faerieGradient)
                        .shadow(color: PuckTheme.orb.opacity(0.4), radius: 6)
                    
                    Text("Puck")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(PuckTheme.primaryGradient)
                    
                    Text("v2")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(PuckTheme.orb.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(PuckTheme.orb.opacity(0.08))
                                .overlay(
                                    Capsule()
                                        .stroke(PuckTheme.orb.opacity(0.15), lineWidth: 0.5)
                                )
                        )
                }
                
                Text(puckSubtitleText)
                    .font(.system(.caption, design: .default))
                    .foregroundStyle(PuckTheme.orb.opacity(0.4))
                    .italic()
            }
            
            Spacer()
            
            dependencyBadges
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    private var dependencyBadges: some View {
        HStack(spacing: 6) {
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
        "I dream of a world where URLs fear me.",
        "The Faerie Dragon hunts your media.",
        "Phase Shift through bandwidth limits.",
        "Illusory Orb deployed... downloading.",
        "Dream Coil ensnares your playlist.",
        "Ethereal Jaunt into the download realm.",
        "Puck claims what the web tries to hide.",
        "Waning Rift tears through your queue.",
        "A mischievous spirit of downloads.",
        "The Dreaming Pool awaits your URLs.",
    ]
    
    // MARK: - URL Input
    
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .font(.caption)
                    .foregroundStyle(PuckTheme.orb.opacity(0.6))
                Text("Summon URLs")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary.opacity(0.85))
            }
            
            TextEditor(text: $viewModel.urlInput)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: PuckTheme.cardRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: PuckTheme.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: PuckTheme.cardRadius)
                        .stroke(PuckTheme.orb.opacity(viewModel.urlInput.isEmpty ? 0.08 : 0.2), lineWidth: 0.5)
                )
                .frame(minHeight: 80, maxHeight: 120)
                .overlay(alignment: .topLeading) {
                    if viewModel.urlInput.isEmpty {
                        Text("Paste URLs here, or drag & drop into the Dreaming Pool...")
                            .foregroundStyle(PuckTheme.orb.opacity(0.25))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
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
            .tint(PuckTheme.orb.opacity(0.85))
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
            } else if viewModel.items.contains(where: { $0.status == .queued }) {
                Button {
                    viewModel.startProcessing()
                } label: {
                    Label("Start Queue", systemImage: "play.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green.opacity(0.85))
            }
            
            Spacer()
            
            Button {
                viewModel.openOutputFolder()
            } label: {
                Label("Open Folder", systemImage: "folder")
            }
            
            Button {
                showSettings.toggle()
            } label: {
                Label("Settings", systemImage: showSettings ? "gear.badge.checkmark" : "gear")
                    .contentTransition(.symbolEffect(.replace))
            }
        }
    }
    
    // MARK: - Download Queue
    
    private var downloadQueueSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(PuckTheme.orb.opacity(0.5))
                    Text("Queue")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text("\(viewModel.items.count)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(PuckTheme.orb.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(PuckTheme.orb.opacity(0.06))
                    )
                    .contentTransition(.numericText())
                
                Spacer()
                
                if viewModel.items.contains(where: { $0.status == .completed }) {
                    Button("Clear Completed") {
                        viewModel.removeCompleted()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(PuckTheme.orb.opacity(0.4))
                }
                
                Button("Clear All") {
                    viewModel.clearAll()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.items) { item in
                        DownloadItemRow(item: item) {
                            viewModel.revealInFinder(item)
                        } onImport: {
                            viewModel.importToNLE(item)
                        } onRetry: {
                            viewModel.startSingleItem(item)
                        } onRemove: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                viewModel.removeItem(item)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 14)
                .animation(.spring(duration: 0.35, bounce: 0.2), value: viewModel.items.count)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(PuckTheme.orb.opacity(0.03))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(emptyStatePulse ? 1.2 : 0.8)
                
                Image(systemName: "moon.stars")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(PuckTheme.faerieGradient)
                    .shadow(color: PuckTheme.orb.opacity(0.3), radius: 12)
                    .scaleEffect(emptyStatePulse ? 1.05 : 1.0)
                    .opacity(emptyStatePulse ? 0.8 : 1.0)
            }
            
            VStack(spacing: 6) {
                Text("The Dreaming Pool is empty")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary.opacity(0.6))
                Text("Paste a URL above or drag & drop to begin the Phase Shift")
                    .font(.caption)
                    .foregroundStyle(PuckTheme.orb.opacity(0.3))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                emptyStatePulse = true
            }
        }
        .onDisappear {
            emptyStatePulse = false
        }
    }
    
    // MARK: - Drop Overlay
    
    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay {
                ZStack {
                    // Ambient glow
                    Circle()
                        .fill(PuckTheme.orb.opacity(0.08))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                    
                    VStack(spacing: 10) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(PuckTheme.faerieGradient)
                            .shadow(color: PuckTheme.orb.opacity(0.5), radius: 16)
                            .symbolEffect(.bounce, options: .repeating, value: isDropTargeted)
                        Text("Release into the Dream Coil")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(PuckTheme.primaryGradient)
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        PuckTheme.faerieGradient,
                        style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                    )
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
                .fill(available ? PuckTheme.orb : .red.opacity(0.8))
                .frame(width: 5, height: 5)
                .shadow(color: available ? PuckTheme.orb.opacity(0.5) : .red.opacity(0.4), radius: 4)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(available ? PuckTheme.orb.opacity(0.7) : .red.opacity(0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
        .overlay(
            Capsule()
                .stroke(available ? PuckTheme.orb.opacity(0.12) : .red.opacity(0.12), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.3), value: available)
    }
}

#Preview {
    ContentView()
}
