import Foundation

extension Int64 {
    func formattedFileSize() -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: self)
    }
}

extension Int {
    func formattedFileSize() -> String {
        Int64(self).formattedFileSize()
    }
}
