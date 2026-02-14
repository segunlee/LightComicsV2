import ArchiveFileCoreInterface
import Foundation
import Logger

// MARK: - ReaderImageArchiveDataProvider

@MainActor
final class ReaderImageArchiveDataProvider: ReaderImageDataProvider {
  // MARK: - Properties

  private let archiveCore: ArchiveFileCoreInterface
  private var tempDirectoryURL: URL?

  // MARK: - Initialization

  init(filePath: String, archiveCore: ArchiveFileCoreInterface) {
    self.archiveCore = archiveCore
    super.init(filePath: filePath)
  }

  // MARK: - ReaderDataProvider

  override func fetch() async throws {
    let fileManager = FileManager.default
    let fileName = URL(fileURLWithPath: filePath).lastPathComponent

    guard fileManager.fileExists(atPath: filePath) else {
      Log.error("Archive not found: \(fileName)")
      throw ReaderDataProviderError.emptyContent(filePath)
    }

    Log.info("Extracting archive: \(fileName)")
    let tempDir = fileManager.temporaryDirectory
      .appendingPathComponent("LightComics_\(UUID().uuidString)")
    try archiveCore.extract(archivePath: filePath, to: tempDir.path)
    tempDirectoryURL = tempDir

    // Recursively scan for image files (archives may have nested directories)
    var allImages: [String] = []
    if let enumerator = fileManager.enumerator(atPath: tempDir.path) {
      while let relativePath = enumerator.nextObject() as? String {
        let ext = URL(fileURLWithPath: relativePath).pathExtension.lowercased()
        if Self.supportedExtensions.contains(ext) {
          allImages.append(tempDir.appendingPathComponent(relativePath).path)
        }
      }
    }

    allImages.sort { $0.localizedStandardCompare($1) == .orderedAscending }

    guard !allImages.isEmpty else {
      Log.error("No images found in archive: \(fileName)")
      throw ReaderDataProviderError.emptyContent(filePath)
    }

    imagePaths = allImages
    Log.info("Archive extracted: \(allImages.count) images from \(fileName)")
    completeFetch()
  }

  override func invalidate() {
    super.invalidate()
    cleanupTempDirectory()
  }

  deinit {
    if let tempURL = tempDirectoryURL {
      try? FileManager.default.removeItem(at: tempURL)
      Log.debug("Cleaned up temp directory")
    }
  }

  // MARK: - Private Methods

  private func cleanupTempDirectory() {
    guard let tempURL = tempDirectoryURL else { return }
    try? FileManager.default.removeItem(at: tempURL)
    tempDirectoryURL = nil
    Log.debug("Archive temp directory cleaned up")
  }
}
