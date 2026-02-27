import SwiftUI

struct SettingsView: View {
    private var settings = AppSettings.shared
    
    @State private var installedEditors: [NLEApp] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            outputSection
            performanceSection
            nleIntegrationSection
            downloadModeSection
            if settings.downloadMode != .audioOnly {
                videoSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            audioSection
        }
        .animation(.spring(duration: 0.35, bounce: 0.15), value: settings.downloadMode)
        .task {
            installedEditors = await NLEIntegrationManager.shared.detectInstalledEditors()
        }
    }
    
    // MARK: - Section Header Helper
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(PuckTheme.orb.opacity(0.6))
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary.opacity(0.85))
        }
    }
    
    // MARK: - Settings Card Helper
    
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            content()
        }
        .padding(PuckTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: PuckTheme.cardRadius)
                .fill(.ultraThinMaterial)
                .opacity(0.4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PuckTheme.cardRadius)
                .stroke(PuckTheme.orb.opacity(0.06), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: PuckTheme.cardRadius))
    }
    
    // MARK: - Hint Text Helper
    
    private func hintText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(PuckTheme.orb.opacity(0.25))
    }
    
    // MARK: - Output
    
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Output", icon: "folder")
            
            settingsCard {
                HStack {
                    Text(settings.outputDirectory.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(PuckTheme.orb.opacity(0.4))
                        .lineLimit(1)
                        .truncationMode(.head)
                    
                    Spacer()
                    
                    Button("Choose...") {
                        chooseOutputDirectory()
                    }
                }
            }
        }
    }
    
    // MARK: - Performance
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Performance", icon: "bolt.fill")
            
            settingsCard {
                HStack {
                    Text("Parallel Downloads")
                        .frame(width: 140, alignment: .leading)
                    Picker("", selection: Bindable(settings).maxConcurrentDownloads) {
                        Text("1 (Sequential)").tag(1)
                        Text("2").tag(2)
                        Text("4 (Recommended)").tag(4)
                        Text("6").tag(6)
                        Text("8").tag(8)
                    }
                    .labelsHidden()
                }
                
                hintText("Higher values download more videos simultaneously. Use 4–6 for best throughput.")
            }
        }
    }
    
    // MARK: - NLE Integration
    
    private var nleIntegrationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Editor Integration", icon: "film.stack")
            
            settingsCard {
                HStack {
                    Text("Auto-Import")
                        .frame(width: 140, alignment: .leading)
                    Toggle("", isOn: Bindable(settings).autoImportToNLE)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .tint(PuckTheme.orb)
                    Spacer()
                }
                
                if settings.autoImportToNLE {
                    HStack {
                        Text("Target Editor")
                            .frame(width: 140, alignment: .leading)
                        Picker("", selection: Bindable(settings).selectedNLE) {
                            Text("None").tag(NLEApp.none)
                            ForEach(NLEApp.allCases.filter { $0 != .none }) { app in
                                HStack(spacing: 6) {
                                    Image(systemName: app.iconName)
                                    Text(app.displayName)
                                }
                                .tag(app)
                            }
                        }
                        .labelsHidden()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    if !installedEditors.isEmpty {
                        HStack(spacing: 8) {
                            Text("Detected:")
                                .font(.caption)
                                .foregroundStyle(PuckTheme.orb.opacity(0.25))
                            ForEach(installedEditors) { app in
                                HStack(spacing: 3) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(PuckTheme.orb)
                                        .font(.caption2)
                                    Text(app.displayName)
                                        .font(.caption)
                                        .foregroundStyle(PuckTheme.orb.opacity(0.5))
                                }
                            }
                        }
                        .transition(.opacity)
                    }
                    
                    if settings.selectedNLE != .none && !installedEditors.contains(settings.selectedNLE) {
                        Text("\(settings.selectedNLE.displayName) was not detected on this system.")
                            .font(.caption)
                            .foregroundStyle(.orange.opacity(0.8))
                            .transition(.opacity)
                    }
                }
                
                hintText("Automatically import downloaded media into your video editor after download completes.")
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.15), value: settings.autoImportToNLE)
    }
    
    // MARK: - Download Mode
    
    private var downloadModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Download Mode", icon: "arrow.down.circle")
            
            settingsCard {
                HStack {
                    Text("Extract")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: Bindable(settings).downloadMode) {
                        ForEach(DownloadMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .labelsHidden()
                }
                
                if settings.downloadMode == .audioOnly {
                    HStack {
                        Text("Audio Format")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: Bindable(settings).audioFormat) {
                            ForEach(AudioFormat.allCases, id: \.self) { format in
                                Text(format.displayName).tag(format)
                            }
                        }
                        .labelsHidden()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                if settings.downloadMode == .audioOnly && settings.audioFormat == .wav {
                    Text("WAV requires ffmpeg to apply sample rate & bit depth settings.\nInstall via: brew install ffmpeg")
                        .font(.caption)
                        .foregroundStyle(.orange.opacity(0.8))
                        .transition(.opacity)
                } else {
                    hintText("Audio Only extracts audio. Video + Audio downloads both video and audio.")
                }
            }
        }
    }
    
    // MARK: - Video
    
    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Video", icon: "film")
            
            settingsCard {
                HStack {
                    Text("Codec")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: Bindable(settings).videoCodec) {
                        ForEach(VideoCodec.allCases, id: \.self) { codec in
                            Text(codec.displayName).tag(codec)
                        }
                    }
                    .labelsHidden()
                }
                
                hintText("Always downloads highest available quality.")
            }
        }
    }
    
    // MARK: - Audio
    
    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Audio", icon: "waveform")
            
            settingsCard {
                HStack {
                    Text("Sample Rate")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: Bindable(settings).audioSampleRate) {
                        ForEach(AudioSampleRate.allCases, id: \.self) { rate in
                            Text(rate.displayName).tag(rate)
                        }
                    }
                    .labelsHidden()
                }
                
                HStack {
                    Text("Bit Depth")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: Bindable(settings).audioBitDepth) {
                        ForEach(AudioBitDepth.allCases, id: \.self) { depth in
                            Text(depth.displayName).tag(depth)
                        }
                    }
                    .labelsHidden()
                }
            }
        }
    }
    
    
    // MARK: - Actions
    
    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = settings.outputDirectory
        panel.prompt = "Choose"
        
        if panel.runModal() == .OK, let url = panel.url {
            settings.outputDirectory = url
        }
    }
}

#Preview {
    SettingsView()
}
