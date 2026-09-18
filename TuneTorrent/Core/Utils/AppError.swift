import Foundation

// MARK: - AppError
enum AppError: LocalizedError {
    case permissionDenied
    case noSpace(required: Int64, available: Int64)
    case torrentFailed(String)
    case fileNotFound(URL)

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Permission denied. Open Settings to grant access."
        case .noSpace(let r, let a): return "Not enough space. Need \(Formatters.bytes(r)), have \(Formatters.bytes(a))."
        case .torrentFailed(let m): return "Torrent failed: \(m)"
        case .fileNotFound(let u): return "File not found: \(u.lastPathComponent)"
        }
    }
}
