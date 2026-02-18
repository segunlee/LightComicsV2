import QuickLookThumbnailing
import UIKit

// MARK: - ThumbnailCache

actor ThumbnailCache {
  static let shared = ThumbnailCache()

  private let cache: NSCache<NSString, UIImage> = {
    let c = NSCache<NSString, UIImage>()
    c.countLimit = 200
    c.totalCostLimit = 150 * 1_024 * 1_024
    return c
  }()

  private var inFlight: [String: Task<UIImage?, Never>] = [:]

  func thumbnail(for path: String, size: CGSize, scale: CGFloat) async -> UIImage? {
    let key = "\(path)|\(Int(size.width))|\(Int(size.height))"
    let nsKey = key as NSString

    // 1) Cache hit
    if let cached = cache.object(forKey: nsKey) {
      return cached
    }

    // 2) In-flight dedup
    if let existing = inFlight[key] {
      return await existing.value
    }

    // 3) New request
    let task = Task<UIImage?, Never> {
      let url = URL(fileURLWithPath: path)
      let request = QLThumbnailGenerator.Request(
        fileAt: url,
        size: size,
        scale: scale,
        representationTypes: .thumbnail
      )
      guard let representation = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request) else {
        return nil
      }
      return representation.uiImage
    }

    inFlight[key] = task
    let image = await task.value
    inFlight.removeValue(forKey: key)

    if let image {
      let cost = image.cgImage.map { $0.bytesPerRow * Int(size.height) } ?? 0
      cache.setObject(image, forKey: nsKey, cost: cost)
    }

    return image
  }
}
