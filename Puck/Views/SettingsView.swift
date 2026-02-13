import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private var settings = AppSettings.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Configure Puck's abilities")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(20)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    outputSection
                    performanceSection
                    downloadModeSection
                    if settings.downloadMode != .audioOnly {
                        videoSection
                    }
                    audioSection
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 600)
    }
    
    // MARK: - Output
    
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Output", systemImage: "folder")
                .font(.headline)
            
            HStack {
                Text(settings.outputDirectory.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
                
                Spacer()
                
                Button("Choose...") {
                    chooseOutputDirectory()
                }
            }
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Performance
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Performance", systemImage: "bolt.fill")
                .font(.headline)
            
            VStack(spacing: 12) {
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
                
                Text("Higher values download more videos simultaneously. Use 4-6 for best throughput.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Download Mode
    
    private var downloadModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Download Mode", systemImage: "arrow.down.circle")
                .font(.headline)
            
            VStack(spacing: 12) {
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
                }
                
                Text("Audio Only extracts audio. Video + Audio downloads both video and audio.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Video
    
    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Video", systemImage: "film")
                .font(.headline)
            
            VStack(spacing: 12) {
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
                
                HStack {
                    Text("Quality")
                        .frame(width: 100, alignment: .leading)
                    Toggle("Download highest quality", isOn: Bindable(settings).downloadHighestQuality)
                        .toggleStyle(.checkbox)
                }
            }
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Audio
    
    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Audio", systemImage: "waveform")
                .font(.headline)
            
            VStack(spacing: 12) {
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
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
