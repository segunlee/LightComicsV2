import FileKit
import FileSystemCoreInterface
import Foundation
import Logger

// MARK: - FileSystemCore

public final class FileSystemCore: FileSystemCoreInterface, @unchecked Sendable {
  public init() {}

  public func readDirectory(at path: String) throws -> [FileSystemItem] {
    do {
      let baseURL = try documentsBaseURL()
      let targetPath = try resolvePath(path, baseURL: baseURL)
      
      let items = targetPath.children().map { item in
        let modifiedDate = item.modificationDate
        var size: Int64?
        if let fSize = item.fileSize {
          size = Int64(fSize)
        }
        
        return FileSystemItem(
          name: item.fileName,
          path: item.rawValue,
          isDirectory: item.isDirectory,
          childCount: item.children().count,
          modifiedDate: modifiedDate,
          size: size
        )
      }
      Log.debug("readDirectory: \(items.count) items at \(targetPath.fileName)")
      return items
    } catch {
      if let error = error as? FileKitError {
        throw error.error ?? error
      } else {
        throw error
      }
    }
  }

  public func createDirectory(named name: String, at path: String) throws {
    do {
      let baseURL = try documentsBaseURL()
      let targetPath = try resolvePath(path, baseURL: baseURL)
      try (targetPath + name).createDirectory()
      Log.debug("createDirectory: '\(name)' at \(targetPath.fileName)")
    } catch {
      if let error = error as? FileKitError {
        throw error.error ?? error
      } else {
        throw error
      }
    }
  }

  public func deleteItem(at path: String) throws {
    do {
      let baseURL = try documentsBaseURL()
      let targetPath = try resolvePath(path, baseURL: baseURL)
      Log.debug("deleteItem: \(targetPath.fileName)")
      do {
        try targetPath.deleteFile()
      } catch {
        if let error = error as? FileKitError {
          throw error.error ?? error
        } else {
          throw error
        }
      }
    } catch {
      if let error = error as? FileKitError {
        throw error.error ?? error
      } else {
        throw error
      }
    }
  }

  public func moveItem(from sourcePath: String, to destinationPath: String) throws {
    do {
      let baseURL = try documentsBaseURL()
      let source = try resolvePath(sourcePath, baseURL: baseURL)
      let destination = try resolvePath(destinationPath, baseURL: baseURL)
      Log.debug("moveItem: \(source.fileName) -> \(destination.fileName)")
      try source.moveFile(to: destination)
    } catch {
      if let error = error as? FileKitError {
        throw error.error ?? error
      } else {
        throw error
      }
    }
  }

  public func copyItem(from sourcePath: String, to destinationPath: String) throws {
    do {
      let baseURL = try documentsBaseURL()
      let source = try resolvePath(sourcePath, baseURL: baseURL)
      let destination = try resolvePath(destinationPath, baseURL: baseURL)
      Log.debug("copyItem: \(source.fileName) -> \(destination.fileName)")
      try source.copyFile(to: destination)
    } catch {
      if let error = error as? FileKitError {
        throw error.error ?? error
      } else {
        throw error
      }
    }
  }

  private func documentsBaseURL() throws -> URL {
    guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      throw FileSystemCoreError.documentsDirectoryUnavailable
    }
    return url
  }

  private func resolvePath(_ path: String, baseURL: URL) throws -> Path {
    let basePath = Path(baseURL.path).absolute
    let targetPath = Path(path).absolute
    guard targetPath.rawValue.hasPrefix(basePath.rawValue) else {
      Log.error("Path security violation: \(path) is outside Documents")
      throw FileSystemCoreError.pathOutsideDocuments
    }
    return targetPath
  }
}
