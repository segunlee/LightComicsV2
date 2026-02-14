import ArchiveFileCoreInterface
import BookDomainInterface
import Logger
import ReaderFeatureInterface
import UIKit

// MARK: - ReaderFeatureFactoryImpl

final class ReaderFeatureFactoryImpl: ReaderFeatureFactory {
  // MARK: - Properties

  private let bookDomain: BookDomainInterface
  private let archiveCore: ArchiveFileCoreInterface

  private static let imageExtensions: Set<String> = [
    "jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff", "tif", "heic", "heif"
  ]

  private static let archiveExtensions: Set<String> = [
    "zip", "cbz", "rar", "cbr", "7z", "cb7", "tar", "cbt", "gz", "bz2", "xz"
  ]

  private static let supportedExtensions: Set<String> =
    imageExtensions.union(["pdf", "txt", "text", "rtf"]).union(archiveExtensions)

  // MARK: - Initialization

  nonisolated init(bookDomain: BookDomainInterface, archiveCore: ArchiveFileCoreInterface) {
    self.bookDomain = bookDomain
    self.archiveCore = archiveCore
  }

  // MARK: - ReaderFeatureFactory

  func canOpenReader(_ path: String) -> Bool {
    let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
    if FileManager.default.isDirectory(atPath: path) {
      return true
    }
    return Self.supportedExtensions.contains(ext)
  }

  @MainActor
  func makeReaderViewController(filePath: String) -> UIViewController {
    let contentType = resolveContentType(for: filePath)
    let fileName = URL(fileURLWithPath: filePath).lastPathComponent
    Log.info("Creating reader: \(fileName) (\(contentType))")

    let useCase = ReaderUseCaseImpl(bookDomain: bookDomain)

    let dataProvider: ReaderDataProvider
    switch contentType {
    case .image:
      let ext = URL(fileURLWithPath: filePath).pathExtension.lowercased()
      if Self.archiveExtensions.contains(ext) {
        Log.debug("DataProvider: ImageArchive (.\(ext))")
        dataProvider = ReaderImageArchiveDataProvider(filePath: filePath, archiveCore: archiveCore)
      } else {
        Log.debug("DataProvider: ImageDirectory")
        dataProvider = ReaderImageDirectoryDataProvider(filePath: filePath)
      }
    case .pdf:
      Log.debug("DataProvider: PDF")
      dataProvider = ReaderPDFDataProvider(filePath: filePath)
    case .text:
      Log.debug("DataProvider: Text")
      dataProvider = ReaderTextDataProvider(filePath: filePath)
    }

    let viewModel = ReaderViewModel(
      useCase: useCase, contentType: contentType, filePath: filePath, dataProvider: dataProvider
    )
    let viewController = ReaderViewController(viewModel: viewModel)

    if contentType == .text {
      viewController.setupSpeech()
    }

    return viewController
  }

  // MARK: - Private Methods

  private func resolveContentType(for path: String) -> ReaderContentType {
    if FileManager.default.isDirectory(atPath: path) {
      return .image
    }
    let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
    switch ext {
    case "pdf":
      return .pdf
    case "txt", "text", "rtf":
      return .text
    default:
      return .image
    }
  }
}

// MARK: - FileManager + Directory Check

private extension FileManager {
  func isDirectory(atPath path: String) -> Bool {
    var isDir: ObjCBool = false
    return fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
  }
}
