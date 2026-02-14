import Foundation

// MARK: - ArchiveFileCoreInterface

public protocol ArchiveFileCoreInterface: Sendable {
  func extract(archivePath: String, to destinationPath: String) throws
}

// MARK: - ArchiveFileCoreError

public enum ArchiveFileCoreError: LocalizedError {
  case cannotOpenArchive(String)
  case extractionFailed(String)

  // MARK: - LocalizedError

  public var errorDescription: String? {
    switch self {
    case let .cannotOpenArchive(reason):
      "Cannot open archive: \(reason)"
    case let .extractionFailed(reason):
      "Extraction failed: \(reason)"
    }
  }
}
