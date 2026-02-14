import FileSystemCoreInterface
import FinderDomainInterface
import Foundation
import Logger

public final class FinderDomain: FinderDomainInterface, @unchecked Sendable {
  private let fileSystemCore: FileSystemCoreInterface

  public init(fileSystemCore: FileSystemCoreInterface) {
    self.fileSystemCore = fileSystemCore
  }

  public func listFiles(at path: String) throws -> [FileItem] {
    let items = try fileSystemCore.readDirectory(at: path)
    Log.info("Loaded \(items.count) items from \(path)")
    return items.map { item in
      FileItem(
        name: item.name,
        path: item.path,
        isDirectory: item.isDirectory,
        childCount: item.childCount,
        modifiedDate: item.modifiedDate,
        size: item.size
      )
    }
  }

  public func createDirectory(named name: String, at path: String) throws {
    try fileSystemCore.createDirectory(named: name, at: path)
    Log.info("Created directory \(name) at \(path)")
  }

  public func renameItem(at path: String, to newName: String) throws {
    let url = URL(fileURLWithPath: path)
    let destination = url.deletingLastPathComponent().appendingPathComponent(newName).path
    try fileSystemCore.moveItem(from: path, to: destination)
    Log.info("Renamed item \(path) to \(newName)")
  }

  public func deleteItems(at paths: [String]) throws {
    Log.debug("deleteItems: \(paths.map { URL(fileURLWithPath: $0).lastPathComponent })")
    for path in paths {
      try fileSystemCore.deleteItem(at: path)
    }
    Log.info("Deleted \(paths.count) items")
  }

  public func moveItems(at paths: [String], to destinationDirectory: String) throws {
    let destName = URL(fileURLWithPath: destinationDirectory).lastPathComponent
    Log.debug("moveItems: \(paths.count) items -> \(destName)")
    for path in paths {
      let fileName = URL(fileURLWithPath: path).lastPathComponent
      let destination = URL(fileURLWithPath: destinationDirectory).appendingPathComponent(fileName).path
      try fileSystemCore.moveItem(from: path, to: destination)
    }
    Log.info("Moved \(paths.count) items to \(destName)")
  }

  public func cloneItem(at path: String) throws {
    let url = URL(fileURLWithPath: path)
    let parent = url.deletingLastPathComponent().path
    let baseName = url.deletingPathExtension().lastPathComponent
    let fileExtension = url.pathExtension
    let existingItems = try fileSystemCore.readDirectory(at: parent)
    let existingNames = Set(existingItems.map { $0.name })

    var candidateIndex = 0
    var candidateName = "\(baseName) copy"
    while existingNames.contains(candidateNameWithExtension(candidateName, fileExtension: fileExtension)) {
      candidateIndex += 1
      candidateName = "\(baseName) copy \(candidateIndex + 1)"
    }

    let finalName = candidateNameWithExtension(candidateName, fileExtension: fileExtension)
    let destination = URL(fileURLWithPath: parent).appendingPathComponent(finalName).path
    try fileSystemCore.copyItem(from: path, to: destination)
    Log.info("Cloned '\(url.lastPathComponent)' as '\(finalName)'")
  }

  private func candidateNameWithExtension(_ name: String, fileExtension: String) -> String {
    if fileExtension.isEmpty {
      return name
    }
    return "\(name).\(fileExtension)"
  }
}
