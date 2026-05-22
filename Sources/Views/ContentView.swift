import SwiftUI
import UniformTypeIdentifiers

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct ContentView: View {
    @StateObject private var resizer = ImageResizer()
    @State private var droppedURLs: [URL] = []
    @State private var selectedPreset: ResizePreset = .p1080
    @State private var customWidth: String = ""
    @State private var lockAspectRatio: Bool = true
    @State private var selectedFormat: ResizeFormat = .jpeg
    @State private var quality: Double = 0.85
    @State private var isDragging: Bool = false
    @State private var customFileName: String = ""
    @State private var showSuccessHint: Bool = false
    @State private var showWidthError: Bool = false
    
    // Theme Management
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"
    @Environment(\.colorScheme) var systemColorScheme
    
    var currentColorScheme: ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    private var themeIcon: String {
        switch selectedTheme {
        case "light": return "sun.max.fill"
        case "dark": return "moon.fill"
        default: return "desktopcomputer"
        }
    }
    
    private var accentColor: Color {
        Color.accentColor
    }
    
    var body: some View {
        ZStack {
            // Adaptive background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Label("QIResizer", systemImage: "aspectratio.fill")
                        .font(.headline)
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Spacer()
                    
                    // Theme Toggle
                    Button {
                        cycleTheme()
                    } label: {
                        Image(systemName: themeIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Change theme")
                    .help("Change Theme")
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)
                .padding(.bottom, 10)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Drag & Drop Zone
                        dragAndDropArea
                        
                        // Settings Groups
                        VStack(spacing: 16) {
                            settingsSection(title: "Dimensions", icon: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left") {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Size")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Picker("", selection: $selectedPreset) {
                                            ForEach(ResizePreset.allCases) { preset in
                                                Text(preset.rawValue).tag(preset)
                                            }
                                        }
                                        .frame(width: 160)
                                    }
                                    
                                    HStack(spacing: 15) {
                                        if selectedPreset == .custom {
                                            HStack {
                                                Image(systemName: "w.square")
                                                TextField("Width", text: $customWidth)
                                                    .textFieldStyle(.plain)
                                                    .frame(width: 60)
                                                Text("px")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(6)
                                            .background(Color.primary.opacity(0.05))
                                            .cornerRadius(6)
                                            if showWidthError {
                                                Text("Enter 1-10000")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        
                                        Toggle(isOn: $lockAspectRatio) {
                                            Label("Lock Aspect Ratio", systemImage: lockAspectRatio ? "lock.fill" : "lock.open.fill")
                                        }
                                        .toggleStyle(.checkbox)
                                        .font(.caption)
                                    }
                                }
                            }
                            
                            settingsSection(title: "Output Settings", icon: "doc.badge.gearshape") {
                                VStack(spacing: 12) {
                                    HStack(alignment: .top, spacing: 20) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Format")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Picker("", selection: $selectedFormat) {
                                                ForEach(ResizeFormat.allCases) { format in
                                                    Text(format.rawValue).tag(format)
                                                }
                                            }
                                            .frame(width: 100)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Custom Name")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("Optional", text: $customFileName)
                                                .textFieldStyle(.plain)
                                                .padding(6)
                                                .background(Color.primary.opacity(0.05))
                                                .cornerRadius(6)
                                        }
                                    }
                                    
                                    if selectedFormat == .jpeg || selectedFormat == .heic {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text("Quality")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text("\(Int(quality * 100))%")
                                                    .font(.caption.monospacedDigit())
                                                    .foregroundColor(accentColor)
                                            }
                                            Slider(value: $quality, in: 0.1...1.0)
                                                .accentColor(accentColor)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 10)
                }
                
                // Footer Area
                VStack(spacing: 0) {
                    Divider().background(Color.primary.opacity(0.1))
                    
                    VStack {
                        if resizer.isProcessing {
                            processingView
                        } else {
                            footerControls
                        }
                    }
                    .padding(20)
                    .background(VisualEffectView(material: .underWindowBackground, blendingMode: .withinWindow))
                }
            }
        }
        .frame(minWidth: 600, minHeight: 650)
        .preferredColorScheme(currentColorScheme)
        .onChange(of: resizer.isProcessing) { oldValue, newValue in
            if oldValue == true && newValue == false && !resizer.results.isEmpty {
                withAnimation {
                    showSuccessHint = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation {
                        showSuccessHint = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func cycleTheme() {
        switch selectedTheme {
        case "system": selectedTheme = "light"
        case "light": selectedTheme = "dark"
        default: selectedTheme = "system"
        }
    }
    
    // MARK: - Components
    
    private var dragAndDropArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isDragging ? accentColor : Color.primary.opacity(0.15),
                    style: StrokeStyle(lineWidth: 2, dash: isDragging ? [] : [6, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDragging ? accentColor.opacity(0.1) : Color.primary.opacity(0.03))
                )
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
            
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: isDragging ? "arrow.down.doc.fill" : "plus.viewfinder")
                        .font(.system(size: 32))
                        .foregroundColor(accentColor)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                }
                
                if droppedURLs.isEmpty {
                    VStack(spacing: 6) {
                        Text("Drop your images here")
                            .font(.title3.bold())
                        Text("Supports PNG, JPG, and HEIC")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: selectFiles) {
                            Text("Browse Files")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Browse files button")
                        .padding(.top, 5)
                    }
                } else {
                    VStack(spacing: 6) {
                        Text("\(droppedURLs.count) images selected")
                            .font(.title3.bold())
                        
                        HStack(spacing: 15) {
                            Button(action: selectFiles) {
                                Label("Add", systemImage: "plus.circle")
                            }
                            .buttonStyle(.link)
                            
                            Button(action: { droppedURLs = [] }) {
                                Label("Clear", systemImage: "trash")
                            }
                            .buttonStyle(.link)
                            .foregroundColor(.red.opacity(0.8))
                        }
                    }
                }
            }
        }
        .frame(height: 220)
        .onDrop(of: [.fileURL], delegate: ImageDropDelegate(isDragging: $isDragging, urls: $droppedURLs))
    }
    
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundColor(.primary.opacity(0.7))
            
            VStack {
                content()
            }
            .padding(16)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Resizing images...")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(resizer.progress * 100))%")
                    .font(.caption.monospacedDigit())
            }
            
            ProgressView(value: resizer.progress)
                .progressViewStyle(.linear)
                .accentColor(accentColor)

            Button("Cancel") {
                resizer.cancel()
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Cancel image processing")
        }
    }
    
    private var footerControls: some View {
        HStack {
            if !resizer.results.isEmpty {
                statsView
            } else if showSuccessHint {
                Label("All images resized successfully!", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption.bold())
            }
            
            Spacer()
            
            Button(action: startResizing) {
                HStack {
                    Text("Resize Now")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: droppedURLs.isEmpty ? [Color.gray.opacity(0.2)] : [accentColor, accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(10)
                .foregroundColor(.white)
                .shadow(color: accentColor.opacity(droppedURLs.isEmpty ? 0 : 0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(droppedURLs.isEmpty)
        }
    }
    
    private var statsView: some View {
        let totalOriginal = resizer.results.reduce(0) { $0 + $1.originalSize }
        let totalNew = resizer.results.reduce(0) { $0 + $1.newSize }
        let saving = totalOriginal > 0 ? Double(totalOriginal - totalNew) / Double(totalOriginal) * 100 : 0
        
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text("Saved \(Int(saving))%")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                Text("in total size")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(totalOriginal.formattedFileSize()) → \(totalNew.formattedFileSize())")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                if !self.droppedURLs.contains(url) {
                    self.droppedURLs.append(url)
                }
            }
        }
    }
    
    private func startResizing() {
        let panel = NSOpenPanel()
        panel.message = "Choose a folder to save resized images"
        panel.prompt = "Select Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let destinationURL = panel.url {
            performResize(to: destinationURL)
        }
    }
    
    private func performResize(to destinationURL: URL) {
        let width: CGFloat
        let height: CGFloat?

        if selectedPreset == .custom {
            guard let w = Double(customWidth), w > 0, w <= 10000 else {
                showWidthError = true
                return
            }
            width = CGFloat(w)
            height = nil
        } else {
            width = selectedPreset.width ?? 1080
            height = selectedPreset.height
        }

        showWidthError = false
        
        Task {
            await resizer.resize(
                urls: droppedURLs,
                targetWidth: width,
                targetHeight: height,
                lockAspectRatio: lockAspectRatio,
                format: selectedFormat,
                quality: quality,
                destinationURL: destinationURL,
                customFileName: customFileName
            )
        }
    }
}

// Reuse the existing DropDelegate logic but with improved visual state handling
struct ImageDropDelegate: DropDelegate {
    @Binding var isDragging: Bool
    @Binding var urls: [URL]
    
    func performDrop(info: DropInfo) -> Bool {
        isDragging = false
        let providers = info.itemProviders(for: [.fileURL])
        
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                if UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true {
                    DispatchQueue.main.async {
                        if !urls.contains(url) {
                            urls.append(url)
                        }
                    }
                }
            }
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {
        withAnimation {
            isDragging = true
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation {
            isDragging = false
        }
    }
}
