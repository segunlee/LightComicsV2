import Foundation
import Logger

// MARK: - ReaderImageDirectoryDataProvider

@MainActor
final class ReaderImageDirectoryDataProvider: ReaderImageDataProvider {
  // MARK: - Properties

  private(set) var initialIndex: Int = 0

  // MARK: - ReaderDataProvider

  override func fetch() async throws {
    let fileManager = FileManager.default
    let fileName = URL(fileURLWithPath: filePath).lastPathComponent

    guard fileManager.fileExists(atPath: filePath) else {
      Log.error("Path not found: \(fileName)")
      throw ReaderDataProviderError.emptyContent(filePath)
    }

    var isDir: ObjCBool = false
    fileManager.fileExists(atPath: filePath, isDirectory: &isDir)
    let ext = URL(fileURLWithPath: filePath).pathExtension.lowercased()

    let scanDirectory: String

    if isDir.boolValue {
      scanDirectory = filePath
      Log.debug("Scanning directory: \(fileName)")
    } else if Self.supportedExtensions.contains(ext) {
      scanDirectory = URL(fileURLWithPath: filePath).deletingLastPathComponent().path
      Log.debug("Scanning parent directory for image: \(fileName)")
    } else {
      throw ReaderDataProviderError.emptyContent(filePath)
    }

    let directoryURL = URL(fileURLWithPath: scanDirectory)
    let contents = try fileManager.contentsOfDirectory(atPath: scanDirectory)
    let filtered = contents
      .filter { Self.supportedExtensions.contains(URL(fileURLWithPath: $0).pathExtension.lowercased()) }
      .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
      .map { directoryURL.appendingPathComponent($0).path }

    guard !filtered.isEmpty else {
      Log.error("No images found in directory")
      throw ReaderDataProviderError.emptyContent(filePath)
    }

    imagePaths = filtered

    // For single image file, find the tapped file's index
    if !isDir.boolValue, Self.supportedExtensions.contains(ext) {
      let tappedFileName = URL(fileURLWithPath: filePath).lastPathComponent
      if let index = filtered.firstIndex(where: { URL(fileURLWithPath: $0).lastPathComponent == tappedFileName }) {
        initialIndex = index
        Log.debug("Tapped image at index \(index): \(tappedFileName)")
      }
    }

    Log.info("Directory loaded: \(filtered.count) images")
    completeFetch()
  }
}
