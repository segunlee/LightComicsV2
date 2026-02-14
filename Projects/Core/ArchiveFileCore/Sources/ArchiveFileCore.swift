import ArchiveFileCoreInterface
import CLibArchive
import Foundation
import Logger

// MARK: - ArchiveFileCore

public final class ArchiveFileCore: ArchiveFileCoreInterface, @unchecked Sendable {
  // MARK: - Initialization

  public init() {}

  // MARK: - Public Methods

  public func extract(archivePath: String, to destinationPath: String) throws {
    let fileName = URL(fileURLWithPath: archivePath).lastPathComponent
    Log.info("Extracting archive: \(fileName)")
    Log.debug("Archive path: \(archivePath), destination: \(destinationPath)")

    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: destinationPath) {
      try fileManager.createDirectory(atPath: destinationPath, withIntermediateDirectories: true)
      Log.debug("Created destination directory")
    }

    let archiveReader = archive_read_new()
    defer { archive_read_free(archiveReader) }

    archive_read_support_format_all(archiveReader)
    archive_read_support_filter_all(archiveReader)

    // iOS returns US-ASCII from nl_langinfo(CODESET), causing non-ASCII
    // filenames (Korean, Chinese, Japanese, etc.) to fail decoding.
    // See: https://github.com/libarchive/libarchive/issues/1572
    archive_read_set_options(archiveReader, "hdrcharset=UTF-8")
    Log.debug("Archive reader configured with UTF-8 charset")

    let result = archive_read_open_filename(archiveReader, archivePath, 10240)
    guard result == ARCHIVE_OK else {
      let message = archiveErrorMessage(archiveReader)
      Log.error("Cannot open archive: \(message)")
      throw ArchiveFileCoreError.cannotOpenArchive(message)
    }

    let diskWriter = archive_write_disk_new()
    defer { archive_write_free(diskWriter) }

    let flags = ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_FFLAGS
    archive_write_disk_set_options(diskWriter, Int32(flags))
    archive_write_disk_set_standard_lookup(diskWriter)

    var entry: OpaquePointer?
    var extractedCount = 0
    var skippedCount = 0

    while true {
      let readResult = archive_read_next_header(archiveReader, &entry)
      if readResult == ARCHIVE_EOF { break }

      guard readResult == ARCHIVE_OK || readResult == ARCHIVE_WARN else {
        let message = archiveErrorMessage(archiveReader)
        Log.error("Extraction failed at entry \(extractedCount): \(message)")
        throw ArchiveFileCoreError.extractionFailed(message)
      }

      guard let entry else { continue }

      let pathName: String
      if let utf8Name = archive_entry_pathname_utf8(entry) {
        pathName = String(cString: utf8Name)
      } else if let wideName = archive_entry_pathname_w(entry) {
        pathName = wcharToString(wideName)
      } else if let rawName = archive_entry_pathname(entry) {
        pathName = String(cString: rawName)
      } else {
        skippedCount += 1
        continue
      }

      // Skip macOS metadata directories
      if pathName.hasPrefix("__MACOSX") || pathName.hasPrefix("._") {
        skippedCount += 1
        continue
      }

      let fullPath = (destinationPath as NSString).appendingPathComponent(pathName)
      archive_entry_set_pathname(entry, fullPath)

      let writeResult = archive_write_header(diskWriter, entry)
      guard writeResult == ARCHIVE_OK else {
        let message = archiveErrorMessage(diskWriter)
        Log.error("Failed to write entry '\(pathName)': \(message)")
        throw ArchiveFileCoreError.extractionFailed(message)
      }

      if archive_entry_size(entry) > 0 {
        try copyData(from: archiveReader, to: diskWriter)
      }

      archive_write_finish_entry(diskWriter)
      extractedCount += 1
    }

    Log.info("Extraction complete: \(extractedCount) entries extracted, \(skippedCount) skipped")
  }

  // MARK: - Private Methods

  private func copyData(from reader: OpaquePointer?, to writer: OpaquePointer?) throws {
    var buffer: UnsafeRawPointer?
    var size: Int = 0
    var offset: Int64 = 0

    while true {
      let result = archive_read_data_block(reader, &buffer, &size, &offset)
      if result == ARCHIVE_EOF { return }

      guard result == ARCHIVE_OK else {
        let message = archiveErrorMessage(reader)
        throw ArchiveFileCoreError.extractionFailed(message)
      }

      let writeResult = archive_write_data_block(writer, buffer, size, offset)
      guard writeResult == ARCHIVE_OK else {
        let message = archiveErrorMessage(writer)
        throw ArchiveFileCoreError.extractionFailed(message)
      }
    }
  }

  private func wcharToString(_ pointer: UnsafePointer<wchar_t>) -> String {
    var length = 0
    while pointer[length] != 0 { length += 1 }
    let scalars = (0 ..< length).compactMap { UnicodeScalar(UInt32(bitPattern: pointer[$0])) }
    return String(String.UnicodeScalarView(scalars))
  }

  private func archiveErrorMessage(_ archive: OpaquePointer?) -> String {
    if let errorString = archive_error_string(archive) {
      return String(cString: errorString)
    }
    return "Unknown archive error"
  }
}
