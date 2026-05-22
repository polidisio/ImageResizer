import Foundation
import AppKit
import UniformTypeIdentifiers

enum ResizeFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"
    case heic = "HEIC"
    
    var id: String { self.rawValue }
    
    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .heic: return .heic
        }
    }
}

enum ResizePreset: String, CaseIterable, Identifiable {
    case p480 = "480p"
    case p720 = "720p"
    case p1080 = "1080p"
    case mobileClassic = "Smartphone Classic"
    case mobilePlus = "Smartphone Plus"
    case mobilePro = "Smartphone Pro"
    case tabletPro = "Tablet Pro"
    case desktopStd = "Desktop Standard"
    case desktopPro = "Desktop Pro"
    case k4 = "4K"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    var width: CGFloat? {
        switch self {
        case .p480: return 640
        case .p720: return 1280
        case .p1080: return 1920
        case .mobileClassic: return 1242
        case .mobilePlus: return 1242
        case .mobilePro: return 1290
        case .tabletPro: return 2048
        case .desktopStd: return 2560
        case .desktopPro: return 2880
        case .k4: return 3840
        case .custom: return nil
        }
    }
    
    var height: CGFloat? {
        switch self {
        case .p480: return 480
        case .p720: return 720
        case .p1080: return 1080
        case .mobileClassic: return 2208
        case .mobilePlus: return 2688
        case .mobilePro: return 2796
        case .tabletPro: return 2732
        case .desktopStd: return 1600
        case .desktopPro: return 1800
        case .k4: return 2160
        case .custom: return nil
        }
    }
}

struct ProcessingResult: Identifiable {
    let id = UUID()
    let originalName: String
    let originalSize: Int64
    let newSize: Int64
    let success: Bool
    let error: String?
}

class ImageResizer: ObservableObject {
    @Published var progress: Double = 0
    @Published var isProcessing: Bool = false
    @Published var results: [ProcessingResult] = []
    
    func resize(
        urls: [URL],
        targetWidth: CGFloat,
        targetHeight: CGFloat?,
        lockAspectRatio: Bool,
        format: ResizeFormat,
        quality: Double,
        destinationURL: URL? = nil,
        customFileName: String? = nil
    ) async {
        await MainActor.run {
            self.isProcessing = true
            self.progress = 0
            self.results = []
        }
        
        var completedCount = 0
        let totalCount = urls.count
        
        for (index, url) in urls.enumerated() {
            let result = await processImage(
                at: url,
                targetWidth: targetWidth,
                targetHeight: targetHeight,
                lockAspectRatio: lockAspectRatio,
                format: format,
                quality: quality,
                destinationURL: destinationURL,
                customFileName: customFileName,
                index: index,
                total: totalCount
            )
            
            completedCount += 1
            let currentProgress = Double(completedCount) / Double(totalCount)
            
            await MainActor.run {
                self.results.append(result)
                self.progress = currentProgress
            }
        }
        
        await MainActor.run {
            self.isProcessing = false
        }
    }
    
    private func processImage(
        at url: URL,
        targetWidth: CGFloat,
        targetHeight: CGFloat?,
        lockAspectRatio: Bool,
        format: ResizeFormat,
        quality: Double,
        destinationURL: URL?,
        customFileName: String?,
        index: Int,
        total: Int
    ) async -> ProcessingResult {
        let originalSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0
        let originalName = url.lastPathComponent
        
        guard let image = NSImage(contentsOf: url) else {
            return ProcessingResult(originalName: originalName, originalSize: originalSize, newSize: 0, success: false, error: "Could not load image")
        }
        
        let originalSize_cg = image.size
        let finalHeight: CGFloat
        
        if lockAspectRatio {
            let ratio = originalSize_cg.height / originalSize_cg.width
            finalHeight = targetWidth * ratio
        } else {
            finalHeight = targetHeight ?? originalSize_cg.height
        }
        
        let newSize = NSSize(width: targetWidth, height: finalHeight)
        let resizedImage = NSImage(size: newSize)

        let sourceRect = NSRect(origin: .zero, size: originalSize_cg)
        let destRect = NSRect(origin: .zero, size: newSize)
        resizedImage.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)
        
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return ProcessingResult(originalName: originalName, originalSize: originalSize, newSize: 0, success: false, error: "Failed to create bitmap representation")
        }
        
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: quality
        ]
        
        let fileExtension: String
        let bitmapType: NSBitmapImageRep.FileType
        
        switch format {
        case .png:
            fileExtension = "png"
            bitmapType = .png
        case .jpeg:
            fileExtension = "jpg"
            bitmapType = .jpeg
        case .heic:
            return await saveWithCGImageDestination(
                image: resizedImage,
                format: format,
                quality: quality,
                originalURL: url,
                originalSize: originalSize,
                destinationURL: destinationURL,
                customFileName: customFileName,
                index: index,
                total: total
            )
        }
        
        guard let imageData = bitmapImage.representation(using: bitmapType, properties: properties) else {
            return ProcessingResult(originalName: originalName, originalSize: originalSize, newSize: 0, success: false, error: "Failed to generate image data")
        }
        
        let finalDestinationURL = getDestinationURL(originalURL: url, extension: fileExtension, customDir: destinationURL, customFileName: customFileName, index: index, total: total)
        
        do {
            try imageData.write(to: finalDestinationURL)
            let newFileSize = (try? finalDestinationURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? Int64(imageData.count)
            return ProcessingResult(originalName: originalName, originalSize: originalSize, newSize: newFileSize, success: true, error: nil)
        } catch {
            return ProcessingResult(originalName: originalName, originalSize: originalSize, newSize: 0, success: false, error: error.localizedDescription)
        }
    }
    
    private func saveWithCGImageDestination(
        image: NSImage,
        format: ResizeFormat,
        quality: Double,
        originalURL: URL,
        originalSize: Int64,
        destinationURL: URL?,
        customFileName: String?,
        index: Int,
        total: Int
    ) async -> ProcessingResult {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ProcessingResult(originalName: originalURL.lastPathComponent, originalSize: originalSize, newSize: 0, success: false, error: "Failed to get CGImage")
        }
        
        let fileExtension = format.rawValue.lowercased()
        let finalDestinationURL = getDestinationURL(originalURL: originalURL, extension: fileExtension, customDir: destinationURL, customFileName: customFileName, index: index, total: total)
        
        guard let destination = CGImageDestinationCreateWithURL(finalDestinationURL as CFURL, format.utType.identifier as CFString, 1, nil) else {
            return ProcessingResult(originalName: originalURL.lastPathComponent, originalSize: originalSize, newSize: 0, success: false, error: "Failed to create image destination")
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        if CGImageDestinationFinalize(destination) {
            let newFileSize = (try? finalDestinationURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0
            return ProcessingResult(originalName: originalURL.lastPathComponent, originalSize: originalSize, newSize: newFileSize, success: true, error: nil)
        } else {
            return ProcessingResult(originalName: originalURL.lastPathComponent, originalSize: originalSize, newSize: 0, success: false, error: "Failed to finalize image destination")
        }
    }
    
    private func getDestinationURL(originalURL: URL, extension ext: String, customDir: URL?, customFileName: String?, index: Int, total: Int) -> URL {
        let baseName: String
        if let custom = customFileName, !custom.isEmpty {
            baseName = "\(custom)_\(index + 1)"
        } else {
            baseName = "\(originalURL.deletingPathExtension().lastPathComponent)_resized"
        }
        
        let newFileName = "\(baseName).\(ext)"
        
        if let customDir = customDir {
            return customDir.appendingPathComponent(newFileName)
        } else {
            return originalURL.deletingLastPathComponent().appendingPathComponent(newFileName)
        }
    }
}
