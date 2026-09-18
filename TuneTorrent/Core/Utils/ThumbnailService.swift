import UIKit
import QuickLook

// MARK: - ThumbnailService
actor ThumbnailService {
    private var cache: [String: UIImage] = [:]

    func thumbnail(for url: URL, size: CGSize = CGSize(width: 120, height: 120)) async -> UIImage? {
        let key = url.path + "\(Int(size.width))"
        if let c = cache[key] { return c }
        let ext = url.pathExtension.lowercased()
        if ["mp3","m4a","wav","flac","aac","aiff","opus"].contains(ext) {
            // audio: try artwork via AVAsset already in Song; else music note
            return nil
        }
        if ["jpg","jpeg","png","heic","webp","gif"].contains(ext) {
            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                let thumb = await img.byPreparingThumbnail(ofSize: size)
                if let t = thumb { cache[key]=t; return t }
            }
        }
        if ["mp4","mov","m4v","mkv","avi"].contains(ext) {
            let req = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: UIScreen.main.scale, representationTypes: .thumbnail)
            if let thumb = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: req) {
                cache[key]=thumb.uiImage; return thumb.uiImage
            }
        }
        return nil
    }
}
