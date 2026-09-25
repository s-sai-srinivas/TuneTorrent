import Foundation

// MARK: - TorrentParser (Magnet & Torrent Metadata)
enum TorrentParser {
    struct MagnetInfo {
        var infoHash: String
        var name: String
        var trackers: [URL]
        var exactSize: Int64?
    }

    static func parseMagnet(_ magnet: String) -> MagnetInfo? {
        guard magnet.hasPrefix("magnet:?") else { return nil }
        var hash = ""
        var name = ""
        var trackers: [URL] = []
        var exactSize: Int64? = nil

        let queryPart = String(magnet.dropFirst("magnet:?".count))
        let pairs = queryPart.components(separatedBy: "&")

        for pair in pairs {
            let kv = pair.components(separatedBy: "=")
            guard kv.count >= 2 else { continue }
            let key = kv[0]
            let val = kv.dropFirst().joined(separator: "=").removingPercentEncoding ?? kv[1]

            if key == "xt" && val.hasPrefix("urn:btih:") {
                hash = String(val.dropFirst("urn:btih:".count))
            } else if key == "dn" {
                name = val
            } else if key == "tr", let u = URL(string: val) {
                trackers.append(u)
            } else if key == "xl", let s = Int64(val) {
                exactSize = s
            }
        }

        guard !hash.isEmpty else { return nil }
        if name.isEmpty {
            name = "Torrent-\(hash.prefix(8))"
        }
        return MagnetInfo(infoHash: hash, name: name, trackers: trackers, exactSize: exactSize)
    }
}
