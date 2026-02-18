import ArchiveFileCoreInterface
import Foundation
import PDFKit
import UIKit

// MARK: - CoverImageProvider

actor CoverImageProvider {
  static let shared = CoverImageProvider()

  private var archiveCore: (any ArchiveFileCoreInterface)?

  private let cache: NSCache<NSString, UIImage> = {
    let c = NSCache<NSString, UIImage>()
    c.countLimit = 200
    c.totalCostLimit = 100 * 1_024 * 1_024
    return c
  }()

  private var inFlight: [String: Task<UIImage?, Never>] = [:]

  // MARK: Private Constants

  private let imageExtensions: Set<String> = [
    "jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff", "tif", "heic", "heif"
  ]

  private let archiveExtensions: Set<String> = [
    "zip", "cbz", "rar", "cbr", "7z", "cb7", "tar", "cbt", "gz", "bz2", "xz"
  ]

  // MARK: Public Methods

  func configure(archiveCore: any ArchiveFileCoreInterface) {
    self.archiveCore = archiveCore
  }

  func cover(for path: String, size: CGSize, scale: CGFloat) async -> UIImage? {
    let key = "\(path)|\(Int(size.width))|\(Int(size.height))" as NSString

    if let cached = cache.object(forKey: key) {
      return cached
    }

    let stringKey = key as String
    if let existing = inFlight[stringKey] {
      return await existing.value
    }

    let task = Task<UIImage?, Never> { [weak self] in
      guard let self else { return nil }
      return await self.loadCover(path: path, size: size, scale: scale)
    }

    inFlight[stringKey] = task
    let image = await task.value
    inFlight.removeValue(forKey: stringKey)

    if let image {
      let cost = image.cgImage.map { $0.bytesPerRow * Int(size.height) } ?? 0
      cache.setObject(image, forKey: key, cost: cost)
    }

    return image
  }

  // MARK: Private Methods

  private func loadCover(path: String, size: CGSize, scale: CGFloat) async -> UIImage? {
    var isDir: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
    guard exists else { return nil }

    if isDir.boolValue {
      return loadDirectoryCover(path: path)
    }

    let ext = URL(fileURLWithPath: path).pathExtension.lowercased()

    if ext == "pdf" {
      return loadPDFCover(path: path, size: size, scale: scale)
    }

    if archiveExtensions.contains(ext) {
      return await loadArchiveCover(path: path)
    }

    return nil
  }

  private func loadDirectoryCover(path: String) -> UIImage? {
    guard let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else { return nil }
    let imageFiles = contents
      .filter { imageExtensions.contains(($0 as NSString).pathExtension.lowercased()) }
      .sorted()
    guard let first = imageFiles.first else { return nil }
    return UIImage(contentsOfFile: (path as NSString).appendingPathComponent(first))
  }

  private func loadArchiveCover(path: String) async -> UIImage? {
    guard let archiveCore else { return nil }
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: tempDir) }
      try archiveCore.extract(archivePath: path, to: tempDir.path)
      return findFirstImage(in: tempDir.path)
    } catch {
      return nil
    }
  }

  private func findFirstImage(in directoryPath: String) -> UIImage? {
    guard let enumerator = FileManager.default.enumerator(atPath: directoryPath) else { return nil }
    var imagePaths: [String] = []
    while let file = enumerator.nextObject() as? String {
      let ext = (file as NSString).pathExtension.lowercased()
      if imageExtensions.contains(ext) {
        imagePaths.append(file)
      }
    }
    imagePaths.sort()
    guard let first = imagePaths.first else { return nil }
    let fullPath = (directoryPath as NSString).appendingPathComponent(first)
    return UIImage(contentsOfFile: fullPath)
  }

  private func loadPDFCover(path: String, size: CGSize, scale: CGFloat) -> UIImage? {
    guard let document = PDFDocument(url: URL(fileURLWithPath: path)),
          let page = document.page(at: 0) else { return nil }
    let thumbnailSize = CGSize(width: size.width * scale, height: size.height * scale)
    return page.thumbnail(of: thumbnailSize, for: .mediaBox)
  }
}
